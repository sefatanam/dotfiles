/**
 * markdown-polish
 *
 * pi-tui's Markdown renderer strips the leading "#" from h1/h2 but prints the
 * literal marker for h3 and deeper (see pi-tui markdown.js, the `heading` case:
 * `depth >= 3 ? headingStyleFn(headingPrefix) + headingText : headingText`).
 *
 * This transformer rewrites deep headings into h2 with a depth glyph, so they
 * pick up the h2 styling (bold + mdHeading colour) while hierarchy stays
 * readable. Source markdown is transformed before parsing, so code fences must
 * be tracked manually to avoid mangling comments like `### section` inside a
 * shell snippet.
 */

const DEPTH_GLYPH = { 3: "▸", 4: "▹", 5: "·", 6: "·" };

// Leading indent up to 3 spaces still counts as an ATX heading in CommonMark.
// Trailing "#" runs are an optional closing sequence and are dropped.
const HEADING = /^( {0,3})(#{3,6})[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$/;

// Opening/closing fence: ``` or ~~~ (3+), optionally indented up to 3 spaces.
const FENCE = /^( {0,3})(`{3,}|~{3,})(.*)$/;

export function polishMarkdown(markdown) {
  if (!markdown.includes("#")) return markdown;

  const lines = markdown.split("\n");
  let fence = null; // { char, length } while inside a fenced block
  let changed = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const fenceMatch = FENCE.exec(line);

    if (fenceMatch) {
      const char = fenceMatch[2][0];
      const length = fenceMatch[2].length;
      if (!fence) {
        // An opening fence carries the info string; a closing one never does.
        fence = { char, length };
        continue;
      }
      // Only a fence of the same char and at least as long closes the block.
      if (char === fence.char && length >= fence.length && fenceMatch[3].trim() === "") {
        fence = null;
      }
      continue;
    }

    if (fence) continue;

    const heading = HEADING.exec(line);
    if (!heading) continue;

    const [, indent, hashes, text] = heading;
    lines[i] = `${indent}## ${DEPTH_GLYPH[hashes.length]} ${text}`;
    changed = true;
  }

  return changed ? lines.join("\n") : markdown;
}

export default function markdownPolish(pi) {
  pi.registerMarkdownTransformer((markdown) => polishMarkdown(markdown));
}
