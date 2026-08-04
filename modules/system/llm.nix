{ pkgs, lib, ... }:

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

    loadModels = [
      # Coding. 35B total / 3B active, 23 GB on disk.
      "qwen3.6:35b-a3b"
      # General purpose. 20B MoE, 13 GB on disk.
      "gpt-oss:20b"
    ];

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

      # 64k rather than the 32k default. Was 128k, halved because the GPU
      # that runs inference also drives the Hyprland desktop, and the Asahi
      # GPU has limited preemption: processing a full 128k-token context
      # pegged the GPU for minutes and froze the UI. 64k caps that worst
      # case at ~30-45s while still letting the model see a lot of code.
      # Heap is not the limit here (KV at 64k is only ~1.3 GiB on top of
      # 21.7 GiB weights); desktop responsiveness is.
      OLLAMA_CONTEXT_LENGTH = "65536";
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
}
