/**
 * Jest pre-setup for Expo/React Native:
 * Ensure globals exist BEFORE jest-expo preset runs.
 */
if (typeof global.window === 'undefined') { global.window = {}; }
if (typeof global.navigator === 'undefined') { global.navigator = {}; }
// Optional: stub RAF if needed by animations
if (typeof global.requestAnimationFrame === 'undefined') {
  global.requestAnimationFrame = (cb) => setTimeout(cb, 0);
}
