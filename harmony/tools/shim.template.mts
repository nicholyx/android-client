// Runtime shims for the HarmonyOS globals the logic modules touch ($r, AppStorage).
// Imported first so the globals exist before any module code runs.
const store = new Map();

globalThis.$r = (s) => s; // Resource references collapse to their id string under test

globalThis.AppStorage = {
  setOrCreate(k, v) { store.set(k, v); },
  set(k, v) { store.set(k, v); },
  get(k) { return store.get(k); },
  has(k) { return store.has(k); },
  clear() { store.clear(); },
  __store: store,
};

export {};
