/*
 * Uses duck-typing to determine if the object is an actual Error object.
 *
 * (can't use instanceof() if things are cross frame/iframe/window so duck-typing is safer).
 */
export const isErrorObject = function(e){ return Boolean(e && e.stack && e.message) }
