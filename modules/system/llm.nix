{ pkgs, lib, inputs, ... }:

# Local LLM inference on Asahi, served by ollama over the M1 Max GPU.
#
# Two hard constraints shape everything below; both were measured on this
# machine (M1 Max, 64 GB, Mesa 26.0.6 / Honeykrisp) rather than assumed.
#
# 1. The GPU is only reachable through Vulkan. There is no Metal and no
#    CUDA/ROCm here, so the stock `pkgs.ollama` runs CPU-only. Measured on
#    a 2.2k-token prompt with qwen3:4b:
#        Vulkan   pp 160 tok/s   tg 20   tok/s
#        CPU (8t) pp  44 tok/s   tg  4.8 tok/s
#    i.e. CPU inference is ~4x slower and not worth using.
#
# 2. Honeykrisp advertises a 31.3 GiB Vulkan heap (not the full 62 GB of
#    unified memory). Weights + KV cache must fit inside it, or llama.cpp
#    silently spills layers to CPU and collapses to the ~5 tok/s case.
#    This is why OLLAMA_MAX_LOADED_MODELS is pinned to 1 below.
#
# Model choice follows from a third measurement: token generation here is
# bandwidth-bound at only ~48 GB/s effective (M1 Max's theoretical is
# ~400), so throughput tracks *active* parameters, not total ones. A dense
# 40B at q4 would read ~24 GB per token and land near 2 tok/s. Both models
# below are therefore MoE with ~3B active params. Measured generation on a
# 2.2k-token prompt, all fully GPU-resident:
#     qwen3:4b        2.5 GB dense    20.0 tok/s
#     gpt-oss:20b      13 GB MoE      21.7 tok/s
#     qwen3.6:35b-a3b  23 GB MoE      22.8 tok/s
# Size on disk barely moves the number; active parameter count is what
# matters. Swapping either model for a dense one of similar size would
# drop it to single digits.

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;

    # Static user, and DynamicUser force-disabled below. Setting `user`
    # alone is NOT enough: the nixpkgs module keeps DynamicUser = true in
    # the unit regardless, so systemd still redirects the state dir to the
    # root-only /var/lib/private/ollama and it's easy to end up with a
    # second, divergent store in ~/.ollama. The result was models silently
    # "disappearing" depending on which store you looked at.
    user = "ollama";
    group = "ollama";
    # Pin the store to one stable, ollama-owned path. modelsDir defaults to
    # ${home}/models, i.e. /var/lib/ollama/models — a real directory now
    # that DynamicUser is off, not a /var/lib/private symlink.
    home = "/var/lib/ollama";

    environmentVariables = {
      # The coding model alone is 21.7 GiB of the 31.3 GiB heap. Keeping a
      # second model resident would overflow it and force a CPU spill, so
      # ollama must evict before loading another.
      OLLAMA_MAX_LOADED_MODELS = "1";

      # Honeykrisp does support flash attention (llama.cpp reports
      # "flash_attn = enabled", not the "auto" fallback), and it keeps the
      # KV cache small enough to afford the 128k context below.
      OLLAMA_FLASH_ATTENTION = "1";

      # Loads here take ~4 minutes, against a 5 minute default, so cold
      # boots intermittently lose the race and ollama SIGKILLs its own
      # runner with "timed out waiting" — which looks like a crash but is
      # self-inflicted. Full GPU offload means llama.cpp loads with
      # mmap = false, so all 23 GB is read in and copied into a 21.7 GiB
      # Vulkan buffer before the first token; measured 17:05:12 start ->
      # 17:08:54 first prompt served. Give it real headroom.
      OLLAMA_LOAD_TIMEOUT = "15m";

      # Tried and rejected: GGML_VK_MAX_NODES_PER_SUBMIT=16, on the theory
      # that Hyprland stalls because the Asahi GPU preempts only at
      # command-buffer boundaries, so smaller submissions would open gaps
      # for the compositor. Verified it reached llama-server (checked
      # /proc/<pid>/environ, not just the unit env) and the desktop was
      # still unusable. The queue appears to be FIFO across submissions
      # rather than round-robin between contexts, so shrinking buffers just
      # queues more of them ahead of the compositor's frame for the same
      # total wait. Priority arbitration is not an option either: the GL
      # path Hyprland renders through (asahi_dri.so, Mesa 26.1.6) has no
      # context-priority support, and while Honeykrisp exposes
      # VK_EXT_global_priority, ggml has no knob to request a low-priority
      # queue. Only creating real GPU idle time works — see num_gpu below.

      # qwen3.6's full native window. Previously 64k, on the theory that a
      # bigger window would itself slow things down. Measured, and it does
      # not: attention cost scales with tokens actually in the sequence, not
      # with the size of the window allocated. Same ~9.6k-token prompt at
      # both settings:
      #     n_ctx  65536   pp 136 tok/s   tg 17.98 tok/s   24 GB resident
      #     n_ctx 262144   pp 146 tok/s   tg 18.83 tok/s   28 GB resident
      # (differences are run-to-run noise). The only real cost is the KV
      # cache, allocated up front at load time: +4 GB on every load, even
      # for a two-line chat. 28 GB against a 31.3 GiB heap still fits, but
      # the headroom is no longer generous — if KV allocation ever starts
      # failing, this is the first thing to lower.
      #
      # What does NOT change is that filling the window is expensive: at
      # ~140 tok/s, 262k tokens is ~35 minutes of prompt processing, and
      # prompt processing is exactly the phase that stalls the compositor
      # 6.4x (see the lag notes below). So this raises a ceiling rather than
      # making anything faster — it removes an artificial truncation point,
      # and the cost is only paid by sessions that actually grow that large.
      OLLAMA_CONTEXT_LENGTH = "262144";

      # The 31.3 GiB Vulkan heap is not a hardware limit: Honeykrisp
      # advertises exactly half of system RAM (SYSMEM_HEAP_FRACTION in
      # mesa's src/asahi/vulkan/hk_physical_device.c) and reads HK_SYSMEM
      # (bytes) as an override. Verified 2026-08-11 with vulkaninfo:
      # 31.31 GiB stock -> 48.00 GiB with this set. Memory is unified, so
      # the kernel allocates GPU pages from regular RAM on demand either
      # way — the heap size only gates what allocations the driver will
      # attempt.
      #
      # 55 GiB leaves ~7 GiB for the rest of the system, with the 16 GiB
      # swapfile below as the backstop for desktop anonymous memory. Beware
      # that the driver accounts "available" against its own usage only,
      # not actual free RAM, so an overcommitted heap ends in the OOM
      # killer rather than a clean Vulkan error. Motivation:
      # qwen3-coder-next (80B-A3B, 51 GB at Q4) was stuck at 24/49 GPU
      # layers (~3.4 tok/s); at 55 GiB even full 49/49 offload (~53 GiB
      # with KV) should fit. Re-tune num_gpu in the qwen3-coder-next:fit
      # Modelfile after the first rebuild with this.
      HK_SYSMEM = "59055800320";
    };
  };

  # This machine ran with no swap at all, which was fine while the largest
  # model was 23 GB. qwen3-coder-next is 48.2 GiB of weights (~52 GB) on 62
  # GB of RAM, leaving under 10 GB for the desktop — and with no swap,
  # crossing that line means the OOM killer rather than a slowdown.
  #
  # The point is not to page out the model. llama.cpp mmaps the GGUF, so
  # weights are file-backed page cache and are not swap candidates anyway.
  # It is to give idle anonymous memory (browser tabs, editors) somewhere to
  # go so the model has room, and to turn a hard kill into degraded
  # performance. swappiness is left at its default: raising it would favour
  # keeping the mmapped weights resident, but at the cost of desktop
  # responsiveness, and that trade-off is not measured here.
  #
  # 16 GiB, on ext4 root with 444 GB free, so size is not a concern.
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  # Desktop lag during inference: measured, and mostly unfixable here.
  #
  # Probe method that finally gave real numbers: time repeated `grim`
  # captures. grim goes through wlr-screencopy, so it forces the compositor
  # to render and GPU-copy a frame. Hyprland's IPC (`hyprctl`) is NOT a
  # usable proxy — it stayed at ~10 ms through 74 s of prompt processing
  # while rendering was badly stalled, because the IPC socket is served
  # independently of the render path, and a static screen under VFR barely
  # renders at all.
  #
  # Median GPU round-trip through the compositor, qwen3.6:35b-a3b at 42/42:
  #     idle                 81 ms
  #     token generation    124 ms   (1.5x — barely noticeable)
  #     prompt processing   519 ms   (6.4x — this is the "unusable" case)
  # So the lag is specifically PROMPT PROCESSING, not generation. It bites
  # at the start of each agent turn, where a ~27k-token context takes
  # minutes, and is why the lag feels intermittent rather than constant.
  #
  # Everything tried against it, and the result:
  #   - GGML_VK_MAX_NODES_PER_SUBMIT=16 (smaller command buffers): no
  #     effect, verified it reached the runner via /proc/<pid>/environ.
  #   - num_batch 128 (from 512, smaller matmul dispatches): no effect —
  #     525 ms vs 519 ms — and halves prompt processing, 136 -> 69 tok/s.
  #     Strictly a loss; do not re-add it.
  #   - Queue priority: unavailable. The GL path Hyprland renders through
  #     (asahi_dri.so, Mesa 26.1.6) has no context-priority support, and
  #     though Honeykrisp exposes VK_EXT_global_priority, ggml has no knob
  #     to request a low-priority queue.
  # The common thread: the Asahi queue is FIFO across submissions, so
  # making submissions smaller just queues more of them ahead of the
  # compositor's frame. Nothing yields the GPU.
  #
  # The one thing that DID work was moving layers to CPU (num_gpu), which
  # creates genuine GPU idle rather than relying on arbitration. It was
  # dropped anyway because the price is absurd: on an identical 2752-token
  # prompt, 42/42 gives 20.37 tok/s and 36/42 gives 5.41 tok/s, and even
  # 41/42 falls to ~8. Roughly 4x slower generation to fix lag that only
  # occurs during prompt processing. The -desk variants that did this were
  # deleted 2026-08-04.
  #
  # (A "~2.5% cost" figure for num_gpu 36 was recorded here earlier and was
  # wrong — it came from misreading a journal window where the eval rate
  # belonged to a full-offload load six minutes prior. Correlate
  # `offloaded N/42` with the eval line by timestamp before trusting any
  # number in this file.)
  #
  # Current stance: run 42/42 and accept lag during prompt processing.
  # Use qwen3:4b when the desktop must stay responsive.

  # Force off the module's hardcoded DynamicUser (see the user/group note
  # above). With a static `ollama` user this gives one predictable store at
  # /var/lib/ollama/models that both the service and the `ollama` CLI
  # resolve to, readable with `sudo ls` instead of hidden under
  # /var/lib/private. SupplementaryGroups=["render"] (for GPU access via
  # /dev/dri/renderD128) is set by the module independently of DynamicUser,
  # so Vulkan still works.
  systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;

  # Second serving path: llama-server, started by hand with ~/models/serve.sh (router on
  # :8080). Pinned newer llama.cpp + a local ggml-vulkan patch; see llama-cpp/package.nix.
  # The patch supersedes two conclusions in the lag notes above, measured 2026-11-11/12
  # (~/llm/RESULTS.md):
  #   - Queue priority IS available now: GGML_VK_QUEUE_PRIORITY=low requests a
  #     VK_KHR_global_priority LOW queue. It helps, but is not enough on its own.
  #   - The stall is not FIFO across submissions as such. Honeykrisp chains the dispatches
  #     inside a command stream into one run the compositor cannot cut into (prompt-batch
  #     matmuls are 15-45 ms each). A timestamp write after every op splits that run
  #     (GGML_VK_PREEMPT_POINTS=1). With -ub 64 (5 ms matmuls) the desktop stayed ~95%
  #     smooth during prompt processing, for -30% prompt speed and 0% generation cost.
  #     That is why "smaller batches: no effect" above was true without split points.
  # ollama bundles its own ggml, so none of this applies to the ollama service.
  environment.systemPackages = [
    (import ./llama-cpp/package.nix { inherit pkgs; })
    # allam: small daemon to change -ub/-b and load/unload models (~/cpp/allam, own repo).
    # Flake input github:juacamole/allam; `nix flake update allam` picks up new pushes.
    inputs.allam.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # EXPERIMENT (2026-11-13): re-enable GPU compute preemption.
  # The Asahi kernel disables it for every compute queue
  # (drivers/gpu/drm/asahi/workqueue.rs: "Hack to disable compute preemption until we fix
  # it"), unless DebugFlags::Debug0 (bit 48) is set. Without preemption the compositor must
  # wait for each running compute job to finish, which is the real cause of the desktop lag
  # during inference; macOS runs the same GPU firmware with preemption on and does not lag.
  # Priority is no help: Hyprland's HIGH request is silently MEDIUM in Mesa, and the kernel
  # rejects HIGH/REALTIME with EINVAL.
  # "until we fix it" means known bugs: watch for GPU faults/hangs (journalctl -k) and wrong
  # results (llama-perplexity). Roll back by booting the previous generation or deleting this.
  boot.kernelParams = [ "asahi.debug_flags=0x1000000000000" ];
}
