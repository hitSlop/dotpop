export interface PolkaBarItem {
  id: string;
  title?: string;
  barTitle?: string;
  symbol?: string;
  selected?: boolean;
  isEnabled?: boolean;
  priority?: "normal" | "overflow";
  role?: "normal" | "primary" | "quiet";
  isDestructive?: boolean;
  placement?: "leading" | "center" | "trailing";
  group?: {
    id: string;
    title: string;
    style?: "segment" | "cluster" | "choice";
    placement?: "leading" | "center" | "trailing";
    showsSymbols?: boolean;
    symbol?: string;
  };
}

export interface PolkaDeckSpec {
  field?: {
    kind?: "entry" | "message" | "query" | "filter" | "none";
    placeholder?: string;
    submit?: { label: string; button?: "word" | "arrow" | "check" };
    canSubmit?: boolean;
  };
  input?: "keys" | "none";
  minimizesOnEntry?: boolean;
  keyboard?: {
    kind: "none" | "qwerty" | "numpad" | "decimal" | "custom";
    rows?: Array<Array<{ id: string; label: string; role?: "primary" | "action" | "modifier"; spoken?: string }>>;
  };
  bar?: PolkaBarItem[];
}

interface PolkaWindowBridge {
  deck: {
    set(spec: PolkaDeckSpec): void;
    setFullScreen(enabled: boolean): void;
    onAction(fn: (id: string) => void): void;
    onKeyPress(fn: (key: string) => void): void;
    onSubmit(fn: (payload: { text: string; attachments?: unknown[] }) => void): void;
  };
  keyboard: {
    show(): void;
    minimize(): void;
  };
  haptics?: {
    impact(style?: "light" | "tick" | "success"): void;
  };
}

declare global {
  interface Window {
    polka?: PolkaWindowBridge;
  }
}

export function getPolka(): PolkaWindowBridge | undefined {
  if (typeof window === "undefined") return undefined;
  return window.polka;
}

export function syncPolkaDeck(spec: PolkaDeckSpec): void {
  getPolka()?.deck.set(spec);
}

export function showPolkaKeyboard(): void {
  getPolka()?.keyboard.show();
}

export function minimizePolkaKeyboard(): void {
  getPolka()?.keyboard.minimize();
}

let actionHandler: ((id: string) => void) | null = null;
let submitHandler: ((text: string) => void) | null = null;
let keyHandler: ((key: string) => void) | null = null;
let listenersBound = false;

/**
 * Registers active Polka Touch Bar / composer / keypad handlers for the mounted `.pop`.
 * Completely inert outside Polka (`window.polka === undefined`).
 */
export function bindPolkaHandlers(handlers: {
  onAction?: (id: string) => void;
  onSubmit?: (text: string) => void;
  onKeyPress?: (key: string) => void;
}): () => void {
  const polka = getPolka();
  if (!polka) return () => {};
  actionHandler = handlers.onAction ?? null;
  submitHandler = handlers.onSubmit ?? null;
  keyHandler = handlers.onKeyPress ?? null;
  if (!listenersBound) {
    listenersBound = true;
    polka.deck.onAction((id) => actionHandler?.(id));
    polka.deck.onSubmit((payload) => submitHandler?.(payload?.text ?? ""));
    polka.deck.onKeyPress((key) => keyHandler?.(key));
  }
  return () => {
    actionHandler = null;
    submitHandler = null;
    keyHandler = null;
  };
}
