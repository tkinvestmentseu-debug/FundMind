/** Common Jest setup for RN/Expo tests (RN 0.7x–0.81 safe) */
try { jest.mock("react-native/Libraries/Animated/NativeAnimatedHelper"); } catch (e) {}

jest.mock("react-native-reanimated", () => require("react-native-reanimated/mock"));

// AsyncStorage: użyj wbudowanego mocka z paczki (działa zawsze)
jest.mock("@react-native-async-storage/async-storage", () =>
  require("@react-native-async-storage/async-storage/jest/async-storage-mock")
);