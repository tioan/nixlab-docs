/* Links inside the inline SVG diagrams (<figure class="nx-diagram">, see
   project/conventions.md) to sections of the same page.

   A box that leads somewhere is <a data-target="<heading id>" tabindex="0"
   role="link"> - deliberately without href. The theme cannot cope with SVG
   links: it rewrites every a[href] on load and throws on an SVG <a>, whose
   href is read-only ("Cannot set property href of SVGAElement"), and with
   an href the browser's own jump put the heading under the sticky header
   (both tested 2026-10-22). So this script does the jump, on click and on
   Enter: the target heading just below the header. The address follows by
   itself (navigation.tracking). Only the site loads this file; the PDF has
   no links in its diagrams. */
(() => {
  const jump = (box) => {
    const target = document.getElementById(box.getAttribute("data-target"));
    if (!target) return false;
    const covered = Math.max(0, ...[".md-header", ".md-tabs"].map((s) => {
      const el = document.querySelector(s);
      return el && getComputedStyle(el).display !== "none" ? el.getBoundingClientRect().bottom : 0;
    }));
    window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - covered - 12 });
    return true;
  };
  const boxOf = (event) => event.target.closest && event.target.closest(".nx-diagram [data-target]");
  window.addEventListener("click", (event) => {
    const box = boxOf(event);
    if (box && jump(box)) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);
  window.addEventListener("keydown", (event) => {
    const box = event.key === "Enter" && boxOf(event);
    if (box && jump(box)) event.preventDefault();
  }, true);
})();
