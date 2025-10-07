const { getDefaultConfig } = require('expo/metro-config');
const config = getDefaultConfig(__dirname);

// awaryjnie ustaw ścieżkę do AssetRegistry, gdyby coś ją nadpisało
if (!config.resolver) config.resolver = {};
if (!config.resolver.assetRegistryPath) {
  config.resolver.assetRegistryPath = 'react-native/Libraries/Image/AssetRegistry';
}

module.exports = config;
