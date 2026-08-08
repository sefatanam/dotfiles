#!/usr/bin/env node
/**
 * pi-markdown-patch — strip the literal ``` fence lines from pi's TUI renderer.
 *
 * pi-tui's Markdown component hardcodes the opening and closing fence lines for
 * every code block, so `pi` prints a dim "```typescript" / "```" around code
 * that is already syntax-highlighted and indented. There is no setting or
 * extension hook for this (MarkdownSettings only exposes codeBlockIndent and
 * mermaid), so the renderer itself has to be patched.
 *
 * Re-run this after every `pi` upgrade — bun reinstalls the package and reverts
 * the patch. Running it twice is safe.
 *
 * Usage:
 *   ./pi-markdown-patch.mjs            patch
 *   ./pi-markdown-patch.mjs --revert   restore from the .orig backup
 *   ./pi-markdown-patch.mjs --check    exit 0 if patched, 1 if not
 */

import { existsSync, copyFileSync, readFileSync, writeFileSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { execFileSync } from "node:child_process";

const MARKER = "/* pi-markdown-patch: fences removed */";

const OPEN_FENCE = '                lines.push(this.theme.codeBlockBorder(`\\`\\`\\`${token.lang || ""}`));\n';
const CLOSE_FENCE = '                lines.push(this.theme.codeBlockBorder("```"));\n';

function resolveMarkdownJs() {
  // Follow the `pi` bin symlink to the installed coding-agent, then hop to the
  // sibling pi-tui package. Falls back to `require.resolve`-style guessing only
  // if the bin is missing.
  let piBin;
  try {
    piBin = execFileSync("/bin/sh", ["-c", "command -v pi"], { encoding: "utf8" }).trim();
  } catch {
    piBin = "";
  }
  if (!piBin || !existsSync(piBin)) {
    throw new Error("could not find the `pi` executable on PATH");
  }

  // .../node_modules/@earendil-works/pi-coding-agent/dist/cli.js
  const cli = realpathSync(piBin);
  const nodeModules = dirname(dirname(dirname(dirname(cli)))); // -> node_modules
  const target = join(nodeModules, "@earendil-works", "pi-tui", "dist", "components", "markdown.js");

  if (!existsSync(target)) {
    throw new Error(`resolved pi to ${cli} but found no pi-tui renderer at ${target}`);
  }
  return target;
}

function main() {
  const mode = process.argv[2] ?? "--patch";
  const target = resolveMarkdownJs();
  const backup = `${target}.orig`;
  const source = readFileSync(target, "utf8");
  const patched = source.includes(MARKER);

  if (mode === "--check") {
    console.log(patched ? `patched: ${target}` : `NOT patched: ${target}`);
    process.exit(patched ? 0 : 1);
  }

  if (mode === "--revert") {
    if (!existsSync(backup)) {
      console.error(`no backup at ${backup} — reinstall pi instead: bun add -g @earendil-works/pi-coding-agent`);
      process.exit(1);
    }
    copyFileSync(backup, target);
    console.log(`reverted ${target}`);
    return;
  }

  if (patched) {
    console.log(`already patched: ${target}`);
    return;
  }

  if (!source.includes(OPEN_FENCE) || !source.includes(CLOSE_FENCE)) {
    console.error(
      `pi-tui's code-block renderer no longer matches what this patch expects.\n` +
        `  file: ${target}\n` +
        `pi probably changed upstream — check whether the fences are still hardcoded before updating this script.`,
    );
    process.exit(1);
  }

  if (!existsSync(backup)) copyFileSync(target, backup);

  const next = source.replace(OPEN_FENCE, `                ${MARKER}\n`).replace(CLOSE_FENCE, "");

  writeFileSync(target, next);
  console.log(`patched ${target}\n  backup: ${backup}`);
}

try {
  main();
} catch (err) {
  console.error(`pi-markdown-patch: ${err.message}`);
  process.exit(1);
}
