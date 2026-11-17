{ pkgs }:

# llama.cpp for salz: Vulkan, pinned to a newer commit than nixpkgs, plus a local
# ggml-vulkan patch that keeps the Hyprland desktop usable during inference.
# Every number here was measured on this machine (M1 Max, Honeykrisp); the full
# log is ~/llm/RESULTS.md.
#
# Why not nixpkgs' llama-cpp (b9925): this commit is ~7.5% faster on generation
# and adds --spec-draft-p-min and --reasoning-effort.
#
# The patch (ggml-vulkan-desktop-friendly.patch) adds env vars, all off by default:
#   GGML_VK_QUEUE_PRIORITY=low     request a low VK_KHR_global_priority queue
#   GGML_VK_PREEMPT_POINTS=1       timestamp + barrier after every op in prompt
#                                  batches (graphs >= GGML_VK_PREEMPT_MIN_GFLOPS,
#                                  default 500). Honeykrisp then splits the
#                                  command stream, so the compositor can get the
#                                  GPU between ops instead of waiting behind a
#                                  chain of 15-45 ms matmuls. Cost ~0.
#   GGML_VK_SUBMIT_SLEEP_US, GGML_VK_MAX_FLOPS_PER_SUBMIT
#                                  experiments; not used.
# Combined with -ub 64 (each matmul ~5 ms) the desktop stays ~95% smooth while
# prompts are processed. ~/models/serve.sh sets all of this.
#
# Update 2026-11-13: the real cause is that the Asahi kernel disables GPU compute
# preemption (see boot.kernelParams in ../llm.nix). With it re-enabled, -ub 512 + LOW
# priority is smooth and PREEMPT_POINTS is unnecessary. serve.sh picks the mode itself.
# But with preemption on, a process killed mid-GPU-job faults the GPU, so the patch also
# makes llama-server's SIGTERM/SIGINT cancel in-flight requests (g_server_shutting_down:
# every request then reports "connection closed") instead of waiting for them to finish.
# The process stops after its current decode call and exits cleanly. Signal only the top
# process; in router mode set `stop-timeout` (models.ini) above one decode call.
(pkgs.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (old: {
  # Upstream moved to semver tags (v0.9.0); this commit reports itself as
  # "0.9.0-dev (build 74)". nixpkgs compiles `version` into LLAMA_BUILD_NUMBER, an int,
  # so it must stay numeric.
  version = "74";
  src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "b8abe41a5081728f9f4c824ef810902a11ab7ffd"; # 2026-11-11
    hash = "sha256-l1iTe6yQXK76GXkiE3JnkEACMzFjCzBcW9P7EH+lxmg=";
    # Same as nixpkgs: the build reads COMMIT for the version string.
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };
  # Web UI npm deps for this commit (nixpkgs pins them for its own version).
  npmDepsHash = "sha256-34AKbVBkQZI1+z83Kg4hA43YbxkeDsESKnIt3T5WdL8=";
  patches = (old.patches or [ ]) ++ [ ./ggml-vulkan-desktop-friendly.patch ];
})
