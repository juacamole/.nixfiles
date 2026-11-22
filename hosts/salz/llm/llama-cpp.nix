{ pkgs }:

# llama.cpp with Vulkan, pinned ahead of nixpkgs, plus a local ggml-vulkan
# patch that keeps the desktop usable during inference (docs/llm.md).
(pkgs.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (old: {
  # Compiled into LLAMA_BUILD_NUMBER, an int, so it must stay numeric.
  version = "200";

  src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "8d60873dfb8619f2b5ed31adfbab07cccb40db5c";
    hash = "sha256-Vhdoalgwea8g/06DkrVr/uXjqZ5NvV9nBcnVfe4HQFU=";
    # The build reads COMMIT for its version string.
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  # Web UI: moved from tools/ui to the ui/ monorepo upstream (2026-11); the chat app
  # builds from its own lockfile and imports ui/lib sources by path.
  npmRoot = "ui/apps/chat";

  # Web UI dependencies of this exact commit.
  npmDepsHash = "sha256-3kJJJGgPvtoRozjjvXJ97ljxzt0tshwi88UUd1D3VsI=";

  patches = (old.patches or [ ]) ++ [
    ./ggml-vulkan-desktop-friendly.patch
    # Inkling 2: keep the dense attention bias under the 2 GiB Vulkan buffer limit (2026-11-22).
    ./llama-inkling2-ubatch-cap.patch
  ];
})
