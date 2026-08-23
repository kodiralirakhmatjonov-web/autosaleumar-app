import Foundation

enum AppWebScript {
    static let shell = #"""
    (() => {
      const STYLE_ID = 'asu-native-shell-style';
      const HIDDEN_ATTR = 'data-asu-native-hidden';
      const CSS = `
    :root {
      --asu-native-bottom-inset: 116px;
      --header-height: 0px !important;
      --nav-height: 0px !important;
    }
    html, body {
      margin-top: 0 !important;
      padding-top: 0 !important;
      overscroll-behavior-y: none;
    }
    body {
      padding-bottom: var(--asu-native-bottom-inset) !important;
    }
    header,
    [role="banner"],
    [data-site-header],
    [data-app-header],
    [data-header-root],
    [data-mobile-header] {
      display: none !important;
      visibility: hidden !important;
      height: 0 !important;
      min-height: 0 !important;
      max-height: 0 !important;
      margin: 0 !important;
      padding: 0 !important;
      border: 0 !important;
      overflow: hidden !important;
      pointer-events: none !important;
    }
    [data-asu-native-hidden="1"] {
      display: none !important;
      visibility: hidden !important;
      height: 0 !important;
      min-height: 0 !important;
      max-height: 0 !important;
      margin: 0 !important;
      padding: 0 !important;
      border: 0 !important;
      overflow: hidden !important;
      pointer-events: none !important;
    }
    `;

      const ensureStyle = () => {
        let style = document.getElementById(STYLE_ID);
        if (!style) {
          style = document.createElement('style');
          style.id = STYLE_ID;
          style.textContent = CSS;
          document.head.appendChild(style);
        }
      };

      const hideTopChrome = () => {
        const nodes = document.querySelectorAll(
          'header, [role="banner"], [data-site-header], [data-app-header], [data-header-root], [data-mobile-header], body > nav, #__next > nav, #root > nav'
        );
        nodes.forEach((node) => node.setAttribute(HIDDEN_ATTR, '1'));

        const structuralCandidates = document.querySelectorAll('body > *, #__next > *, #root > *');
        structuralCandidates.forEach((node) => {
          if (!(node instanceof HTMLElement) || node.hasAttribute(HIDDEN_ATTR)) return;
          const rect = node.getBoundingClientRect();
          const style = window.getComputedStyle(node);
          const text = (node.textContent || '').replace(/\s+/g, ' ').trim();
          const hasBrand = /AUTO\s*SALE\s*UMAR/i.test(text) || !!node.querySelector('img[alt*="Auto Sale Umar" i]');
          const hasMenuControl = !!node.querySelector('button[aria-label*="menu" i], button[aria-label*="меню" i], [data-menu-trigger], [aria-controls*="menu" i]');
          const topChrome = rect.top <= 20 && rect.height >= 48 && rect.height <= 190;
          const anchored = style.position === 'fixed' || style.position === 'sticky' || topChrome;
          if (topChrome && anchored && hasBrand && hasMenuControl) {
            node.setAttribute(HIDDEN_ATTR, '1');
          }
        });
      };

      const apply = () => {
        ensureStyle();
        hideTopChrome();
      };

      apply();
      new MutationObserver(apply).observe(document.documentElement, {childList: true, subtree: true});
    })();
    true;
    """#
}
