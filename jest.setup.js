/** Common Jest setup for RN/Expo tests (RN 0.7x–0.81 safe) */
try { jest.mock("react-native/Libraries/Animated/NativeAnimatedHelper"); } catch (e) {}

jest.mock("react-native-reanimated", () => require("react-native-reanimated/mock"));

// AsyncStorage: użyj wbudowanego mocka z paczki (działa zawsze)
jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock")
);
// __suppress_act_warning__
{
  const origError = global.console?.error ?? console.error;
  const ignore = [
    'An update to', // początek komunikatu Reacta o act(...)
    'wrap tests with act'
  ];
  // Podszywamy się pod console.error tylko w teście:
  // przepuszczamy wszystko poza warningiem o act(...)
  // (nie zmienia zachowania appki)
  console.error = (...args) => {
    const msg = (args && args[0] || '') + ''
    if (ignore.some(x => msg.includes(x))) { return }
    origError(...args)
  }
}