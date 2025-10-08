/** Jest config for Expo SDK 50 / RN 0.73.x
 *  - no ts-jest transform (jest-expo handles Babel for RN)
 *  - ignore backups/archives to avoid haste-map "package.json" collisions
 */
module.exports = {
  preset: "jest-expo",
  testEnvironment: "node",
  // DO NOT override "transform" – let jest-expo/Babel do the work
  transformIgnorePatterns: [
    "node_modules/(?!(react-native|@react-native|react-clone-referenced-element|@react-navigation)/)"
  ],
  moduleFileExtensions: ["ts","tsx","js","jsx","json","node"],
  setupFilesAfterEnv: ["@testing-library/react-native/extend-expect"],
  testPathIgnorePatterns: [
    "/node_modules/","/dist/","/build/",
    "/\\.archive/","/__tests__disabled__/"
  ],
  modulePathIgnorePatterns: [
    "<rootDir>/.archive",
    "<rootDir>/__tests__disabled__",
    "<rootDir>/_archive",
    "<rootDir>/.backup",
    "<rootDir>/_backup",
    "<rootDir>/.history"
  ]
};
