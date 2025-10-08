/** Jest config for Expo/RN + ESM in node_modules (with roots & ignores) */
module.exports = {
  preset: 'jest-expo',
  testEnvironment: 'node',
  roots: ['<rootDir>/app','<rootDir>/src','<rootDir>/__tests__'],
  setupFilesAfterEnv: ['@testing-library/react-native/extend-expect','<rootDir>/jest.setup.js'],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': 'babel-jest',
  },
  moduleFileExtensions: ['ts','tsx','js','jsx','json','node'],
  testPathIgnorePatterns: [
    '/node_modules/','/dist/','/build/',
    '/\\.archive/','/_archive/','/__tests__disabled__/'
  ],
  modulePathIgnorePatterns: [
    '/\\.archive/','/_archive/','/\\.history/','/backup/','/backups/'
  ],
  watchPathIgnorePatterns: [
    '/\\.archive/','/_archive/','/\\.history/','/backup/','/backups/'
  ],
  transformIgnorePatterns: [
    'node_modules/(?!(react-native'
      + '|@react-native'
      + '|react-clone-referenced-element'
      + '|@react-navigation'
      + '|expo'
      + '|expo-.*'
      + '|@expo/.*'
      + '|expo-modules-core'
      + '|unimodules-.*'
      + '|react-native-.*'
      + ')/)',
  ],
};