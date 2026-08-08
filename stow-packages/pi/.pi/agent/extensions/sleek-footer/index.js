import { basename } from "node:path";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const fmt = (n) => (n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`);

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

export default function sleekFooter(pi) {
  let enabled = true;
  let phase = "idle"; // idle | thinking | tool:<name>
  let frame = 0;
  let timer = null;
  let liveTui = null;
  let activeSkill = null;

  const startSpin = () => {
    if (timer) return;
    timer = setInterval(() => {
      frame = (frame + 1) % SPINNER.length;
      liveTui?.requestRender();
    }, 90);
  };
  const stopSpin = () => {
    if (timer) clearInterval(timer);
    timer = null;
  };

  const install = (ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      liveTui = tui;
      const unsub = footerData.onBranchChange?.(() => tui.requestRender());
      return {
        dispose: () => { stopSpin(); liveTui = null; unsub?.(); },
        invalidate() {},
        render(width) {
          let input = 0, output = 0, cost = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "message" && e.message.role === "assistant") {
              input += e.message.usage.input;
              output += e.message.usage.output;
              cost += e.message.usage.cost.total;
            }
          }

          const dot =
            phase === "idle"
              ? theme.fg("success", "●")
              : theme.fg("accent", SPINNER[frame]);
          const phaseLabel =
            phase === "idle" ? theme.fg("dim", "ready") : theme.fg("accent", phase);

          const folder = theme.fg("muted", basename(ctx.cwd));
          const branch = footerData.getGitBranch?.();
          const branchStr = branch ? theme.fg("dim", ` (${branch})`) : "";
          const model = theme.fg("muted", ctx.model?.id ?? "no-model");
          const thinking = ctx.thinkingLevel && ctx.thinkingLevel !== "off"
            ? theme.fg("dim", ` ${ctx.thinkingLevel}`)
            : "";

          const left = `${dot} ${phaseLabel}  ${folder}${branchStr}`;
          const right = `${model}${thinking}  ${theme.fg("dim", `↑${fmt(input)} ↓${fmt(output)} $${cost.toFixed(3)}`)}`;

          const gap = Math.max(1, width - visibleWidth(left) - visibleWidth(right));
          const line1 = truncateToWidth(left + " ".repeat(gap) + right, width);

          const statuses = footerData.getExtensionStatuses?.();
          const extBits = statuses
            ? [...statuses.values()].map((s) => String(s || "").trim()).filter(Boolean)
            : [];
          const skillBit = activeSkill ? theme.fg("accent", `⚙ ${activeSkill}`) : "";
          const line2Parts = [skillBit, ...extBits].filter(Boolean);

          if (line2Parts.length === 0) return [line1];
          const line2 = truncateToWidth(line2Parts.join("  "), width);
          return [line1, line2];
        },
      };
    });
  };

  const uninstall = (ctx) => {
    stopSpin();
    ctx.ui.setFooter(undefined);
  };

  pi.on("session_start", (_e, ctx) => { if (enabled) install(ctx); });

  pi.on("input", (event) => {
    const text = String(event?.text || "");
    const match = text.match(/^\/skill:(\S+)/);
    if (match) activeSkill = match[1];
  });

  pi.on("turn_start", () => { phase = "thinking"; startSpin(); });
  pi.on("turn_end", () => { phase = "idle"; activeSkill = null; stopSpin(); liveTui?.requestRender(); });

  pi.on("tool_execution_start", (event) => {
    phase = `tool:${event.toolName}`;
    startSpin();
  });
  pi.on("tool_execution_end", () => { phase = "thinking"; liveTui?.requestRender(); });

  pi.registerCommand("footer", {
    description: "Toggle the sleek footer (/footer off restores the default)",
    handler: (arg, ctx) => {
      const off = (arg || "").trim() === "off";
      enabled = !off;
      if (enabled) install(ctx); else uninstall(ctx);
      ctx.ui.notify(enabled ? "Sleek footer on" : "Default footer restored", "info");
    },
  });
}
