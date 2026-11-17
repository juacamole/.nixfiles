/**
 * Tokens per second in pi's footer stats line, for slow local models (salz llama.cpp router):
 *
 *   ↑8.9k ↓533 R5.8k CH41.9% 8.6t/s pp64 3.7%/262k (auto)
 *
 *   while reading the prompt:  "pp…"
 *   while generating:          "~8.4t/s"   (live estimate: one stream delta ~ one token)
 *   after each response:       "8.6t/s pp64"
 *     gen = usage.output / time from first streamed token to end
 *     pp  = usage.input (uncached prompt tokens) / time from request to first token
 *
 * Works by wrapping pi's built-in FooterComponent (ctx.ui.setFooter) and inserting the
 * text before the context percentage, so everything else in the footer stays stock.
 *
 * Linked from ~/.nixfiles/modules/user/apps/pi.nix (2026-11-14).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { FooterComponent } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Context percentage in the stats line, possibly preceded by colour codes: "3.7%/262k", "?/262k".
const CTX_RE = /(?:\x1b\[[0-9;]*m)*(?:\d+(?:\.\d+)?%|\?)\/\d/;

export default function (pi: ExtensionAPI) {
	let tReq = 0; // request sent
	let tFirst = 0; // first streamed token
	let deltas = 0;
	let lastPaint = 0;
	let text = "t/s–";
	let requestRender: () => void = () => {};

	const fmt = (n: number) => (n >= 100 ? n.toFixed(0) : n.toFixed(1));
	const set = (t: string) => {
		text = t;
		requestRender();
	};

	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = () => tui.requestRender();
			// The built-in footer only needs these parts of the agent session.
			const session = {
				get state() {
					return { model: ctx.model, thinkingLevel: pi.getThinkingLevel() };
				},
				sessionManager: ctx.sessionManager,
				modelRegistry: ctx.modelRegistry,
				getContextUsage: () => ctx.getContextUsage(),
			};
			const inner = new FooterComponent(session as any, footerData);
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose() {
					unsub();
					inner.dispose();
				},
				invalidate() {
					inner.invalidate();
				},
				render(width: number): string[] {
					const lines = inner.render(width);
					const i = lines.findIndex((l) => CTX_RE.test(l));
					if (i < 0) return lines;
					const add = text + " ";
					let line = lines[i].replace(CTX_RE, (m) => theme.fg("dim", add) + m);
					// Take the added width back out of the padding before the model name.
					const n = visibleWidth(add);
					line = line.replace(new RegExp(` {${n}}(?= {2,})`), "");
					lines[i] = visibleWidth(line) > width ? truncateToWidth(line, width, "") : line;
					return lines;
				},
			};
		});
	});

	pi.on("before_provider_request", () => {
		tReq = Date.now();
		tFirst = 0;
		deltas = 0;
		lastPaint = 0;
		set("pp…");
	});

	pi.on("message_update", (event: any) => {
		const t = event.assistantMessageEvent?.type;
		if (t !== "text_delta" && t !== "thinking_delta" && t !== "toolcall_delta") return;
		const now = Date.now();
		if (!tFirst) tFirst = now;
		deltas++;
		const secs = (now - tFirst) / 1000;
		if (secs > 1 && now - lastPaint > 1000) {
			lastPaint = now;
			set(`~${fmt(deltas / secs)}t/s`);
		}
	});

	pi.on("message_end", (event: any) => {
		const m = event.message;
		if (m?.role !== "assistant" || !tReq) return;
		const now = Date.now();
		const parts: string[] = [];
		const out = m.usage?.output ?? 0;
		if (tFirst && out > 0 && now > tFirst) parts.push(`${fmt(out / ((now - tFirst) / 1000))}t/s`);
		const inp = m.usage?.input ?? 0;
		if (tFirst && inp > 50 && tFirst > tReq) parts.push(`pp${fmt(inp / ((tFirst - tReq) / 1000))}`);
		if (parts.length) set(parts.join(" "));
		tReq = 0;
	});
}
