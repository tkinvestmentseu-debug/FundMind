/** Stable Jest config for React Native (no jest-expo) */
module.exports = {
  preset: "react-native",
  testEnvironment: "jsdom",
  roots: ["<rootDir>"],
  setupFiles: ["<rootDir>/jest.presetup.js",],
  setupFilesAfterEnv: ["@testing-library/jest-native/extend-expect", "<rootDir>/jest.setup.ts"],
  transformIgnorePatterns: [
    "node_modules/(?!(react-native|@react-native|react-clone-referenced-element|@react-native-community|expo(modules)?|@expo(nent)?|@testing-library/react-native)/)"
  ],
  testPathIgnorePatterns: ["^<rootDir>/__tests__disabled__/.*", "^<rootDir>/\\.archive/.*"],
  modulePathIgnorePatterns: ["^<rootDir>/__tests__disabled__/.*", "^<rootDir>/\\.archive/.*"],
  watchPathIgnorePatterns: ["^<rootDir>/__tests__disabled__/.*", "^<rootDir>/\\.archive/.*"],
  moduleNameMapper: {
    "\\\\.(css|less|sass|scss)$": "identity-obj-proxy"
  }
};


