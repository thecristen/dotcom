export const isEnter = (key: number | string): boolean =>
  key === "Enter" || key === 13;

export const doOnReturnKey = (e: KeyboardEvent, cb: Function): void =>
  isEnter(e.key || e.keyCode) ? cb(e) : () => {};
