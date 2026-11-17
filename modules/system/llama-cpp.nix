{ pkgs, lib, ... }:

# llama.cpp server on the M1 Max GPU, running alongside ollama (llm.nix).
#
# Reason this exists separately rather than as more ollama tuning: ollama
# cannot do MTP on this machine. See the notes on both points below.
#
# ── Why MTP is worth a second server ────────────────────────────────────────
# Generation here is bandwidth-bound at ~48 GB/s effective, so every token
# costs one full read of the active weights regardless of how little compute
# it needs. Multi-token prediction (llama.cpp PR #22673, merged 2026-05-16)
# uses the extra prediction head Qwen3.6/3.8 were trained with to draft N
# tokens and verify them in a single forward pass — i.e. several tokens per
# weight read. That makes it worth the most exactly where this host hurts.
#
# ── Why ollama can't do it ──────────────────────────────────────────────────
# ollama 0.31.2 does ship the machinery (its bundled llama-server accepts
# `--spec-type draft-mtp`, and its qwen3.6 blob does contain the mtp.* /
# nextn.* tensors), but the server never passes the flag for this model:
# every runner in the journal reports `draft: 0.000 MiB`. Its own MTP path
# (x/mlxrunner) is the MLX backend, i.e. macOS, not Vulkan.
#
# Going the other way — pointing upstream llama.cpp at ollama's blobs to
# reuse the 60 GB already on disk — does not work either. ollama writes a
# non-standard GGUF for this architecture and its fork patches over the
# difference at load time ("detected Ollama-format qwen35moe GGUF; applying
# compatibility fixes"). Upstream b9925 rejects the same file outright:
#     error loading model hyperparameters:
#     key qwen35moe.rope.dimension_sections has wrong array length;
#     expected 4, got 3
# Hence the separate, plain-GGUF model store in /var/lib/llama-cpp/models.

let
  # Vulkan is the only route to this GPU (no Metal, no CUDA/ROCm) — same
  # constraint as llm.nix. Prebuilt in cache.nixos.org for aarch64, so this
  # override costs a download rather than a compile.
  llamaCpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  modelsDir = "/var/lib/llama-cpp/models";

  # Router-mode preset file. Sections are model names as seen by the API;
  # keys are llama-server long options minus the leading dashes.
  # Precedence: CLI args > model section > [*] section.
  #
  # There is no [*] section here on purpose: globals live on the router's
  # ExecStart instead, which child instances inherit. (Note that dropping
  # [*] does NOT remove the stray "default" entry from GET /models — that
  # one is the router's own implicit preset built from its CLI args, and
  # there is no flag to hide it. It is cosmetic; requesting it fails.)
  #
  # Every spec-type below is a measured decision, not a default. Method:
  #   llama-batched-bench   -> cost of a batched decode step
  #   draft acceptance logs -> tokens actually gained per step
  # MTP wins only when accepted-tokens-per-step exceeds the batch cost
  # multiplier, which is true for the two dense models and false for the MoE.
  modelsIni = pkgs.writeText "llama-models.ini" ''
    version = 1

    [qwen3.8-27b-abliterated]
    ; huihui-ai abliterated Qwen3.8-27B. Dense with hybrid attention, so MTP
    ; wins: 5.12 -> 5.86 tok/s at n=2 (73% acceptance); n=3 is a loss.
    ; Q4 is the floor: Q3_K kernels are broken-slow on Honeykrisp.
    model            = ${modelsDir}/Huihui-Qwen3.8-27B-abliterated-UD-Q4_K_XL.gguf
    ctx-size         = 262144
    spec-type        = draft-mtp
    spec-draft-n-max = 2
  '';
in
{
  systemd.services.llama-cpp = {
    description = "llama.cpp server (Vulkan, MTP)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      # Same override as llm.nix. Honeykrisp advertises half of system RAM
      # (SYSMEM_HEAP_FRACTION in mesa's hk_physical_device.c) and reads
      # HK_SYSMEM as a byte-count override. Verified against this exact
      # llama.cpp build: 32066 MiB reported stock, 56320 MiB with this set.
      #
      # NOTE this is shared, not additive: ollama and llama.cpp each believe
      # they have 55 GiB. Memory is unified and the driver accounts
      # "available" against its own usage only, so two large models resident
      # at once ends in the OOM killer, not a Vulkan error. --models-max 1
      # below is the llama.cpp half of that guard; OLLAMA_MAX_LOADED_MODELS
      # is the ollama half. Don't run a big model on both at once.
      HK_SYSMEM = "59055800320";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = lib.concatStringsSep " " [
        "${llamaCpp}/bin/llama-server"
        # No -m: launching without a model is what puts llama-server into
        # router mode, where models are loaded on demand by the "model"
        # field of each request — the ollama behaviour.
        "--models-preset ${modelsIni}"

        # NOTHING IS LOADED AT BOOT. This unit starting does not put any
        # weights in memory: the router is only a dispatcher, and it spawns
        # a child llama-server per model on the first request that names it.
        # Measured: 50 MB RSS and zero GPU while idle, against ~23 GB once
        # the 35B is actually asked for. A model is released again either by
        # POST /models/unload or by requesting a different one (see
        # --models-max below). If you want even the dispatcher to stay down
        # until asked for, set wantedBy = [] above and start it by hand with
        # `systemctl start llama-cpp`.
        "--models-max 1"

        # Globals, rather than an [*] section in the preset: child instances
        # inherit the router's command line and environment.
        #
        # Everything on the GPU. Partial offload is catastrophic here: on an
        # identical 2752-token prompt, 42/42 layers gives 20.4 tok/s and
        # 36/42 gives 5.4 (measured for llm.nix).
        "-ngl 999"
        # Honeykrisp reports "flash_attn = enabled", not the "auto" fallback.
        "-fa on"
        # One slot. Concurrency would multiply the KV cache, and there is
        # only one GPU queue to contend for anyway.
        "-np 1"
        # Use each model's embedded chat template rather than a hardcoded one.
        "--jinja"
        # Put thoughts in message.reasoning_content. The default is "auto";
        # pinning it matters because tapioca's OpenAI provider reads exactly
        # that field (internal/provider/openai.go), and Qwen3.6/3.8 think.
        "--reasoning-format deepseek"

        # ollama's OLLAMA_KEEP_ALIVE equivalent, and it matters more here
        # than it does there: HK_SYSMEM is SHARED between the two services,
        # so a model left resident holds heap that ollama also believes it
        # owns. Verified this actually releases rather than just idling the
        # threads — child RSS fell 1.05 GB -> 0.22 GB and the log printed
        # "entering sleeping state". 300 s matches ollama's default.
        "--sleep-idle-seconds 300"

        # ollama's OLLAMA_LOAD_TIMEOUT exists because full-offload loads
        # there run with mmap disabled and copy the whole file into a Vulkan
        # buffer before serving. llama-server mmaps by default, which is why
        # no equivalent knob is needed here — a cold 23 GB load measured 16 s.
        "--host 127.0.0.1"
        "--port 8080"
      ];

      User = "llama-cpp";
      Group = "llama-cpp";
      # GPU access is via /dev/dri/renderD128. (The card1/card2 "Permission
      # denied" lines that show up in logs are harmless — those are the
      # display nodes, which inference never needs.)
      SupplementaryGroups = [ "render" ];
      StateDirectory = "llama-cpp";
      WorkingDirectory = "/var/lib/llama-cpp";

      Restart = "on-failure";
      RestartSec = 5;

      # A 23 GB model load is a lot of page-cache churn; give it room to
      # finish before systemd calls it dead.
      TimeoutStartSec = "15min";
    };
  };

  users.users.llama-cpp = {
    isSystemUser = true;
    group = "llama-cpp";
    home = "/var/lib/llama-cpp";
  };
  users.groups.llama-cpp = { };

  # llama-cli / llama-bench for interactive use and measurement. Same
  # derivation as the server, so no extra closure.
  environment.systemPackages = [ llamaCpp ];
}
