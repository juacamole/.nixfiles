# Local LLM inference on salz

Everything here was measured on this machine (M1 Max, 64 GB, Mesa Honeykrisp).
The code in `hosts/salz/llm/` carries the values; this file carries the reasons.
The full measurement log is `~/llm/RESULTS.md`.

## Constraints

- **Vulkan is the only way to the GPU.** There is no Metal and no CUDA/ROCm,
  so stock `pkgs.ollama` runs on the CPU, which is about 4x slower
  (qwen3:4b, 2.2k-token prompt: Vulkan 160 tok/s prompt, 20 tok/s
  generation; CPU with 8 threads 44 and 4.8).
- **The Vulkan heap is a driver setting, not a hardware limit.** Honeykrisp
  advertises half of system RAM (31.3 GiB) and reads `HK_SYSMEM` (bytes) as
  an override. It is set to 55 GiB, which leaves about 7 GiB for the desktop.
  Weights plus KV cache must fit inside the heap, or llama.cpp silently
  moves layers to the CPU.
- **Partial offload is catastrophic.** Same 2752-token prompt: 42/42 layers
  on the GPU gives 20.4 tok/s, 41/42 about 8, 36/42 gives 5.4.
- **The heap is shared, not additive.** ollama and llama.cpp each believe
  they own all 55 GiB, and the driver only counts its own usage. Two large
  models loaded at once end in the OOM killer, not in a Vulkan error.
- **Generation is memory-bandwidth-bound** (about 48 GB/s effective), so
  speed follows the number of *active* parameters, not model size. Prefer
  MoE models with about 3B active parameters:

  | Model           | Size          | Generation |
  | --------------- | ------------- | ---------- |
  | qwen3:4b        | 2.5 GB dense  | 20.0 tok/s |
  | gpt-oss:20b     | 13 GB MoE     | 21.7 tok/s |
  | qwen3.6:35b-a3b | 23 GB MoE     | 22.8 tok/s |

  A dense model of similar size drops to single digits.
- Avoid Q3_K quantisations: those kernels are extremely slow on Honeykrisp.

## ollama (port 11434)

| Setting                         | Reason                                                                                                                                                                             |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| static `ollama` user, `DynamicUser` forced off | The NixOS module keeps `DynamicUser = true` even when a user is set, which puts the store in root-only `/var/lib/private` and made models seem to disappear. Now there is one store: `/var/lib/ollama/models`. |
| `OLLAMA_MAX_LOADED_MODELS=1`    | A second resident model would overflow the heap.                                                                                                                                   |
| `OLLAMA_FLASH_ATTENTION=1`      | Honeykrisp supports it, and it keeps the KV cache small enough for the large context.                                                                                              |
| `OLLAMA_LOAD_TIMEOUT=15m`       | A full-offload load copies the whole file into a Vulkan buffer and takes about 4 minutes. With the 5 minute default ollama sometimes kills its own runner ("timed out waiting"). |
| `OLLAMA_CONTEXT_LENGTH=262144`  | Window size does not slow anything down; cost follows the tokens actually present (64k window: 136/18.0 tok/s; 262k window: 146/18.8). The price is 4 GB more KV cache on every load. If KV allocation starts failing, lower this first. |
| 16 GiB swapfile                 | Gives idle desktop memory somewhere to go, so a large model causes a slowdown instead of an OOM kill. Weights are file-backed and are never swapped.                               |

## llama.cpp (router on port 8080)

`llama-cpp.nix` builds llama.cpp at a pinned commit (2026-11-11) with
Vulkan and a local patch. Compared with the nixpkgs version it generates
about 7.5% faster and has `--spec-draft-p-min` and `--reasoning-effort`.

The server is not a systemd unit. [allam](https://github.com/juacamole/allam)
starts and manages it (`~/.config/allam/allam.conf`, presets in
`~/models/models.ini`, launcher `~/models/serve.sh`), and the bar's brain
pill is its front end.

**Why a second server.** Multi-token prediction (MTP) drafts several tokens
and verifies them in one pass, which helps most where each token costs a
full read of the weights. ollama cannot do it here: it never passes
`--spec-type draft-mtp` for these models, and its own MTP path is the MLX
backend. Its model blobs cannot be reused either, because it writes a
non-standard GGUF that upstream rejects
(`qwen35moe.rope.dimension_sections has wrong array length`). Hence a
separate store of plain GGUF files.

**MTP is a per-model decision.** It wins only when the tokens accepted per
step exceed the cost of the batched decode. That holds for dense models
(Qwen3.8-27B: 5.12 to 5.86 tok/s with `spec-draft-n-max = 2` at 73%
acceptance; 3 is a loss) and not for the MoE ones.

**Router mode facts.** Starting without `-m` makes llama-server a router
that loads models on demand, so nothing is in memory until the first request
(50 MB idle). `--models-max 1` is the llama.cpp half of the shared-heap
guard. `--sleep-idle-seconds 300` really releases memory. llama-server
mmaps the model, so a cold 23 GB load takes 16 seconds and needs no load
timeout. `--reasoning-format deepseek` puts thoughts in `reasoning_content`,
the field tapioca's OpenAI provider reads.

**The patch** (`ggml-vulkan-desktop-friendly.patch`) adds environment
variables, all off by default:

- `GGML_VK_QUEUE_PRIORITY=low` requests a low `VK_KHR_global_priority` queue.
- `GGML_VK_PREEMPT_POINTS=1` writes a timestamp after every op in prompt
  batches, which makes Honeykrisp split the command stream so the compositor
  can get in between ops.
- `GGML_VK_SUBMIT_SLEEP_US` and `GGML_VK_MAX_FLOPS_PER_SUBMIT` were
  experiments and are unused.
- It also makes SIGTERM/SIGINT cancel in-flight requests instead of waiting
  for them. With GPU preemption on, a process killed in the middle of a GPU
  job faults the GPU, so the server must stop cleanly after its current
  decode call. Signal only the top process; in router mode keep
  `stop-timeout` above the length of one decode call.

`version` in the derivation must stay numeric: nixpkgs compiles it into
`LLAMA_BUILD_NUMBER`. ollama bundles its own ggml, so none of the patch
applies to it.

## Desktop lag during inference

**How to measure.** Time repeated `grim` captures: they force the compositor
to render and copy a frame. `hyprctl` is useless as a probe, because its
socket keeps answering in 10 ms while rendering is stalled.

Median round trip with qwen3.6:35b-a3b fully offloaded: 81 ms idle, 124 ms
during generation, **519 ms during prompt processing**. The lag is prompt
processing, which is why it comes in bursts at the start of each agent turn.

**Cause.** The Asahi kernel disables GPU compute preemption
(`drivers/gpu/drm/asahi/workqueue.rs`, "until we fix it"), so the compositor
has to wait for each compute job to finish. macOS runs the same GPU firmware
with preemption on and does not lag.

**Current fix (experiment since 2026-11-13).** The kernel parameter
`asahi.debug_flags=0x1000000000000` (debug bit 48) turns preemption back on.
With it, `-ub 512` plus the low-priority queue is smooth and preempt points
are unnecessary. Upstream disabled it for known bugs, so watch
`journalctl -k` for GPU faults and check results with `llama-perplexity`.
To roll back, boot the previous generation or remove the parameter.

**Without preemption**, preempt points plus `-ub 64` keep the desktop about
95% smooth during prompt processing, for 30% less prompt speed and no
generation cost.

**Tried and rejected.** Do not retry these without new evidence.

- `GGML_VK_MAX_NODES_PER_SUBMIT=16`: no effect, even though it verifiably
  reached the runner.
- `num_batch 128` on ollama: no effect on lag (525 vs 519 ms) and it halves
  prompt speed (136 to 69 tok/s).
- Queue priority alone: Hyprland's HIGH request is silently MEDIUM in Mesa,
  and the kernel rejects HIGH and REALTIME.
- Moving layers to the CPU: it does remove the lag, but generation becomes
  about 4x slower.

`cursor.no_hardware_cursors = false` in Hyprland matters here too: a
hardware cursor lives on its own display plane and keeps moving while the
render queue is backed up. Set it to true only if the pointer corrupts.

When reading the journal, match the `offloaded N/42` line with the eval line
by timestamp. A wrong number was once recorded from a load six minutes
earlier.

## Clients

**Claude Code** (`modules/home/claude.nix`, `claude-local` in `zsh.nix`):

- `CLAUDE_CODE_MAX_OUTPUT_TOKENS=1048576` is a ceiling, not a reservation.
  If requests to Anthropic ever fail with a 400 about `max_tokens`, this is
  the cause.
- `API_TIMEOUT_MS` is 30 minutes because a full local context takes minutes
  of prompt processing before the first token.
- `BUN_CONFIG_HTTP_IDLE_TIMEOUT=3600` (seconds). Claude Code is a Bun build,
  and Bun closes HTTP connections that are idle for about 300 seconds.
  During prompt processing the server sends nothing, so requests died at
  4m45s. ollama logs a 500 for the dropped connection, which looks like a
  crash and is not.
- `claude-local` talks to ollama's native `/v1/messages` endpoint, so no
  proxy is needed.
  - `ANTHROPIC_AUTH_TOKEN` is ignored by ollama but must be set. Without it
    the CLI falls back to the real credentials and bills the real API.
  - The small/fast model is the same model on purpose. A different one would
    evict and reload 23 GB for every background task.
  - The output cap is low (16384) here, because the local model can run
    away: one generation produced 65464 tokens over 20 minutes.
- `CLAUDE_CODE_OAUTH_TOKEN` must never be exported globally. It is a
  headless credential, and when present the CLI uses it instead of the
  logged-in session, which silently drops the Max subscription. Pass it per
  invocation where needed:
  `CLAUDE_CODE_OAUTH_TOKEN="$(<~/.claude/oauth-token)" claude -p ...`
- Testing a new session variable: `.zshenv` only exports once per login
  (`__HM_ZSH_SESS_VARS_SOURCED`), so a new terminal does not show it. Log in
  again, or run
  `env -u __HM_ZSH_SESS_VARS_SOURCED zsh -c 'source ~/.zshenv; echo $VAR'`.

**pi** (`modules/home/pi/`) talks to the llama.cpp router.

- Its `settings.json` and `models.json` are written by an activation script
  as normal files, not through the Home Manager options. Those would create
  read-only store symlinks, and pi saves its own changes into
  `settings.json`. On every switch the Nix values are merged over the
  existing settings (Nix wins, keys pi added stay), and `models.json` is
  replaced.
- Local models are slow, so the provider timeout is 30 minutes.
- `skills/caveman` and `extensions/tps.ts` (tokens per second in the footer)
  are linked into `~/.pi/agent`.
