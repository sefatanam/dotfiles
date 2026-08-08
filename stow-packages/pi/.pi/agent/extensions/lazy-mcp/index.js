// @REVIEW: Lazy MCP bridge for pi — spawns serena / context7 stdio MCP servers on demand.
// Token-cheap by design: nothing is spawned and no tools enter the prompt until you run
// /serena or /context7. /mcp-off tears everything down.
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { Type } from "typebox";

const DEFAULT_SERVERS = {
  serena: {
    command: "uvx",
    args: [
      "--from", "git+https://github.com/oraios/serena",
      "serena", "start-mcp-server",
      "--context", "ide-assistant",
      "--enable-web-dashboard", "False",
    ],
    guideline:
      "Use serena_* tools for code navigation: find symbols, find references, read/replace symbol bodies. Prefer them over raw grep for understanding code.",
  },
  context7: {
    command: "npx",
    args: ["-y", "@upstash/context7-mcp"],
    guideline:
      "Use context7_* tools to fetch up-to-date library/framework documentation before answering API questions.",
  },
};

// @REVIEW: merge .pi/mcp.json (project) over defaults. Shape:
// { "autoStart": ["serena"], "servers": { "serena": { "command", "args", "guideline" } } }
const loadProjectConfig = (cwd) => {
  try {
    const cfg = JSON.parse(readFileSync(join(cwd, ".pi", "mcp.json"), "utf8"));
    return {
      servers: { ...DEFAULT_SERVERS, ...(cfg.servers || {}) },
      autoStart: Array.isArray(cfg.autoStart) ? cfg.autoStart : [],
    };
  } catch {
    return { servers: DEFAULT_SERVERS, autoStart: [] };
  }
};

export default function lazyMcp(pi) {
  const live = new Map(); // name -> { proc, tools, rpc }
  let SERVERS = DEFAULT_SERVERS;

  const rpcClient = (proc) => {
    let nextId = 1;
    const pending = new Map();
    let buf = "";
    proc.stdout.on("data", (chunk) => {
      buf += chunk.toString();
      let nl;
      while ((nl = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line) continue;
        try {
          const msg = JSON.parse(line);
          if (msg.id && pending.has(msg.id)) {
            const { resolve, reject } = pending.get(msg.id);
            pending.delete(msg.id);
            msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
          }
        } catch { /* ponytail: ignore non-JSON server chatter */ }
      }
    });
    const call = (method, params) =>
      new Promise((resolve, reject) => {
        const id = nextId++;
        pending.set(id, { resolve, reject });
        proc.stdin.write(JSON.stringify({ jsonrpc: "2.0", id, method, params }) + "\n");
        setTimeout(() => {
          if (pending.has(id)) { pending.delete(id); reject(new Error(`${method} timed out`)); }
        }, 60000);
      });
    return { call };
  };

  const activate = async (name, ctx) => {
    if (live.has(name)) { ctx.ui.notify(`${name} already active`, "info"); return; }
    const cfg = SERVERS[name];
    if (!cfg) { ctx.ui.notify(`Unknown MCP server: ${name}`, "error"); return; }

    ctx.ui.setStatus("lazy-mcp", `starting ${name}...`);
    const proc = spawn(cfg.command, cfg.args, { stdio: ["pipe", "pipe", "inherit"], cwd: ctx.cwd });
    const rpc = rpcClient(proc);

    await rpc.call("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "pi-lazy-mcp", version: "1" },
    });
    proc.stdin.write(JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" }) + "\n");

    const { tools = [] } = await rpc.call("tools/list", {});
    const registered = [];
    for (const t of tools) {
      const toolName = `${name}_${t.name}`;
      pi.registerTool({
        name: toolName,
        label: toolName,
        description: t.description || `${name} tool ${t.name}`,
        parameters: t.inputSchema || Type.Object({}),
        promptGuidelines: [cfg.guideline],
        async execute(_toolCallId, params) {
          const res = await rpc.call("tools/call", { name: t.name, arguments: params });
          const text = (res?.content || [])
            .map((c) => (c.type === "text" ? c.text : JSON.stringify(c)))
            .join("\n");
          return { content: [{ type: "text", text: text || JSON.stringify(res) }] };
        },
      });
      registered.push(toolName);
    }
    live.set(name, { proc, rpc, tools: registered });
    pi.setActiveTools([...pi.getAllTools().map((t) => t.name)]); // ponytail: enable all incl. new
    ctx.ui.setStatus("lazy-mcp", `${name}: ${registered.length} tools`);
    ctx.ui.notify(`${name} MCP active (${registered.length} tools)`, "info");
  };

  const deactivate = (name, ctx) => {
    for (const [n, entry] of live) {
      if (name && n !== name) continue;
      try { entry.proc.kill(); } catch { /* ponytail: best-effort */ }
      pi.setActiveTools(pi.getAllTools().map((t) => t.name).filter((t) => !entry.tools.includes(t)));
      live.delete(n);
      ctx.ui.notify(`${n} MCP stopped`, "info");
    }
    if (live.size === 0) ctx.ui.setStatus("lazy-mcp", "");
  };

  pi.registerCommand("serena", {
    description: "Activate serena MCP (code navigation) on demand",
    handler: (_arg, ctx) => activate("serena", ctx),
  });
  pi.registerCommand("context7", {
    description: "Activate context7 MCP (live docs) on demand",
    handler: (_arg, ctx) => activate("context7", ctx),
  });
  pi.registerCommand("mcp-off", {
    description: "Stop MCP servers and remove their tools (frees tokens)",
    handler: (arg, ctx) => deactivate(arg?.trim() || null, ctx),
  });
  pi.registerCommand("mcp-status", {
    description: "Show configured and live MCP servers",
    handler: (_arg, ctx) => {
      const configured = Object.keys(SERVERS).join(", ") || "none";
      const running = [...live.keys()].join(", ") || "none";
      ctx.ui.notify(`MCP configured: ${configured} | live: ${running}`, "info");
    },
  });

  pi.on("session_start", async (_e, ctx) => {
    const { servers, autoStart } = loadProjectConfig(ctx.cwd);
    SERVERS = servers;
    for (const name of autoStart) await activate(name, ctx);
  });

  pi.on("session_end", (_e, ctx) => deactivate(null, ctx));
}
