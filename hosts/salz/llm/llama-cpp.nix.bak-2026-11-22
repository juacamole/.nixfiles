{ pkgs }:

# llama.cpp with Vulkan, pinned ahead of nixpkgs, plus a local ggml-vulkan
# patch that keeps the desktop usable during inference (docs/llm.md).
(pkgs.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (old: {
  # Compiled into LLAMA_BUILD_NUMBER, an int, so it must stay numeric.
  version = "74";

  src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "b8abe41a5081728f9f4c824ef810902a11ab7ffd";
    hash = "sha256-l1iTe6yQXK76GXkiE3JnkEACMzFjCzBcW9P7EH+lxmg=";
    # The build reads COMMIT for its version string.
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  # Web UI dependencies of this exact commit.
  npmDepsHash = "sha256-34AKbVBkQZI1+z83Kg4hA43YbxkeDsESKnIt3T5WdL8=";

  patches = (old.patches or [ ]) ++ [ ./ggml-vulkan-desktop-friendly.patch ];
})
