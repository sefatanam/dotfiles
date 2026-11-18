// Theme switch shared by every page in site/: cream -> dark -> follow macOS.
// Loaded in <head> so the saved theme applies before first paint; the choice is
// stored under one key, so it carries from one page to the other.
(function () {
  "use strict";
  var root = document.documentElement;
  var themes = ["cream", "dark", "auto"];
  var KEY = "wiki-theme";

  function load() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function save(val) { try { localStorage.setItem(KEY, val); } catch (e) {} }

  var saved = load();
  var current = themes.indexOf(saved) !== -1 ? saved : "cream";

  function apply() {
    var dark = current === "dark" ||
      (current === "auto" && window.matchMedia("(prefers-color-scheme: dark)").matches);
    if (dark) { root.setAttribute("data-theme", "dark"); } else { root.removeAttribute("data-theme"); }
    var btn = document.getElementById("theme");
    if (btn) { btn.textContent = "Theme: " + current; }
  }
  apply();

  document.addEventListener("DOMContentLoaded", function () {
    var btn = document.getElementById("theme");
    if (!btn) { return; }
    apply();
    btn.addEventListener("click", function () {
      current = themes[(themes.indexOf(current) + 1) % themes.length];
      save(current);
      apply();
    });
  });
})();
