(() => {
  const started = performance.timeOrigin;
  const events = [];
  const MAX_EVENTS = 10000;
  const text = (value) => String(value ?? "").replace(/\s+/g, " ").trim().slice(0, 500);
  const describe = (element) => {
    if (!(element instanceof Element)) return {};
    const label = element.labels?.[0]?.innerText || element.getAttribute("aria-label") || element.innerText;
    return {
      tag: element.tagName.toLowerCase(),
      role: element.getAttribute("role") || undefined,
      name: text(label || element.getAttribute("name") || element.id || element.getAttribute("placeholder")),
    };
  };
  const add = (event) => {
    if (events.length < MAX_EVENTS) events.push({ ms: Math.round(performance.now()), url: location.href, ...event });
  };
  const valueOf = (element) => {
    if (!(element instanceof HTMLInputElement || element instanceof HTMLTextAreaElement || element instanceof HTMLSelectElement)) return undefined;
    if (element instanceof HTMLInputElement && element.type === "password") return "[REDACTED]";
    return text(element.value);
  };

  for (const type of ["click", "input", "change", "submit"]) {
    document.addEventListener(type, (event) => {
      const target = event.target;
      add({ type, target: describe(target), value: valueOf(target) });
    }, true);
  }

  new MutationObserver((mutations) => {
    const changes = mutations.map((mutation) => {
      if (mutation.type === "characterData") return text(mutation.target.textContent);
      return [...mutation.addedNodes, ...mutation.removedNodes].map((node) => text(node.textContent)).filter(Boolean).join(" | ");
    }).filter(Boolean);
    if (changes.length) add({ type: "ui-change", text: text(changes.join(" | ")) });
  }).observe(document, { subtree: true, childList: true, characterData: true });

  for (const method of ["pushState", "replaceState"]) {
    const original = history[method];
    history[method] = function (...args) {
      const result = original.apply(this, args);
      add({ type: "navigation", method, to: location.href });
      return result;
    };
  }
  addEventListener("popstate", () => add({ type: "navigation", method: "popstate", to: location.href }));
  Object.defineProperty(window, "__narratedReview", { value: { started, events }, enumerable: false });
})();
