/**
 * Registers the models allam serves that models.json does not list, as the
 * "salz-auto" provider. A separate provider because registerProvider replaces
 * every model of the provider it names, which would drop the tuned salz entries.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const BASE = "http://127.0.0.1:8080/v1";
const DEFAULT_CTX = 32768;

async function allamIds(): Promise<string[]> {
  const { stdout } = await promisify(execFile)("allam", ["ls"], { timeout: 3000 });
  const res = JSON.parse(stdout);
  return res.ok ? res.models.map((m: { id: string }) => m.id) : [];
}

async function knownIds(): Promise<Set<string>> {
  try {
    const cfg = JSON.parse(await readFile(join(homedir(), ".pi/agent/models.json"), "utf8"));
    return new Set(cfg.providers?.salz?.models?.map((m: { id: string }) => m.id) ?? []);
  } catch {
    return new Set();
  }
}

// context_length is the training context; the preset's ctx-size is what the router serves.
async function routerInfo(): Promise<Map<string, { ctx: number; image: boolean }>> {
  const info = new Map();
  try {
    const r = await fetch(`${BASE}/models`, { signal: AbortSignal.timeout(2000) });
    for (const m of (await r.json()).data ?? []) {
      const ctx = /ctx-size = (\d+)/.exec(m.status?.preset ?? "");
      info.set(m.id, {
        ctx: ctx ? Number(ctx[1]) : (m.meta?.n_ctx ?? DEFAULT_CTX),
        image: m.architecture?.input_modalities?.includes("image") ?? false,
      });
    }
  } catch {}
  return info;
}

export default async function (pi: ExtensionAPI) {
  let ids: string[];
  try {
    ids = await allamIds();
  } catch {
    return;
  }
  const known = await knownIds();
  const fresh = ids.filter((id) => !known.has(id));
  if (!fresh.length) return;

  const info = await routerInfo();
  pi.registerProvider("salz-auto", {
    name: "salz (auto)",
    baseUrl: BASE,
    apiKey: "local",
    api: "openai-completions",
    compat: {
      supportsDeveloperRole: false,
      supportsReasoningEffort: false,
      maxTokensField: "max_tokens",
    },
    models: fresh.map((id) => {
      const i = info.get(id);
      return {
        id,
        name: `${id} (salz, auto)`,
        reasoning: true,
        input: i?.image ? ["text", "image"] : ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: i?.ctx ?? DEFAULT_CTX,
        maxTokens: 32768,
      };
    }),
  });
}
