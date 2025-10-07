module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo']
    // NIE dodawaj 'expo-router/babel' – przestarzałe od SDK 50+.
    // Jeśli używasz Reanimated, dołóż na końcu:
    // plugins: ['react-native-reanimated/plugin']
  };
};