/* The inline SVG diagrams (<figure class="nx-diagram">, see
   project/conventions.md) on the site: boxes that jump to a section of the
   page, and a click anywhere else on a diagram opens it enlarged.

   Jump: a box that leads somewhere is <a data-target="<heading id>"
   tabindex="0" role="link"> - deliberately without href. The theme cannot
   cope with SVG links: it rewrites every a[href] on load and throws on an
   SVG <a>, whose href is read-only ("Cannot set property href of
   SVGAElement"), and with an href the browser's own jump put the heading
   under the sticky header (both tested 2026-10-22). So this script does the
   jump, on click and on Enter: the target heading just below the header.
   The address follows by itself (navigation.tracking).

   Enlarge: the theme's GLightbox (docs/assets.nix) only takes images, so a
   click on a diagram outside its boxes opens a GLightbox of its own with a
   copy of the figure - same look and keys as an enlarged image. The boxes
   of the copy still jump: the lightbox closes first.

   Only the site loads this file; the PDF has neither. */
(() => {
  let lightbox = null;

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

  // A box of the enlarged copy: close the lightbox, then jump once it is
  // gone (it restores the page's scroll position while closing).
  const jumpFromLightbox = (box) => {
    if (!document.getElementById(box.getAttribute("data-target"))) return false;
    lightbox.close();
    setTimeout(() => jump(box), 450);
    return true;
  };

  const enlarge = (figure) => {
    if (typeof GLightbox !== "function") return false;
    const copy = figure.cloneNode(true);
    copy.classList.add("nx-diagram-enlarged");
    if (lightbox) lightbox.destroy();
    lightbox = GLightbox({
      elements: [{ content: copy.outerHTML, width: "min(94vw, 1360px)", height: "auto" }],
      // Not "zoom" like the images: Chrome left the SVG's text unpainted
      // after that scale animation (2026-10-22), until something redrew it.
      openEffect: "fade",
      closeEffect: "fade",
      draggable: false,
      touchNavigation: false,
    });
    lightbox.open();
    return true;
  };

  const act = (event) => {
    if (!event.target.closest) return false;
    const box = event.target.closest(".nx-diagram [data-target]");
    if (box) return box.closest(".glightbox-container") ? jumpFromLightbox(box) : jump(box);
    const figure = event.target.closest("figure.nx-diagram");
    return Boolean(figure && !figure.closest(".glightbox-container") && enlarge(figure));
  };

  window.addEventListener("click", (event) => {
    if (act(event)) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);
  window.addEventListener("keydown", (event) => {
    if (event.key === "Enter" && event.target.closest && event.target.closest(".nx-diagram [data-target]") && act(event)) {
      event.preventDefault();
    }
  }, true);
})();
