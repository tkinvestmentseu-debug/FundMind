// Lightweight react-native mock for Jest (version-agnostic)
const React = require("react");
const Noop = (props) => React.createElement("div", props, props && props.children);
const Text = (p) => React.createElement("span", p, p && p.children);
const View = (p) => React.createElement("div", p, p && p.children);
const Pressable = Noop;
const TouchableOpacity = Noop;
const ScrollView = Noop;
const Image = Noop;
const StyleSheet = {
  create: (styles) => styles || {},
  flatten: (s) => s,
};
const Platform = { OS: "ios", select: (obj) => obj && (obj.ios ?? obj.default) };
const Dimensions = { get: () => ({ width: 390, height: 844, scale: 3 }) };
const Linking = { openURL: jest.fn(), canOpenURL: jest.fn().mockResolvedValue(true) };
const NativeModules = {};
const Appearance = { getColorScheme: () => "light" };
function useColorScheme(){ return "light"; }
module.exports = {
  __esModule: true,
  default: { View, Text, Pressable, TouchableOpacity, ScrollView, Image, StyleSheet, Platform, Dimensions, Linking, NativeModules, Appearance, useColorScheme },
  View, Text, Pressable, TouchableOpacity, ScrollView, Image, StyleSheet, Platform, Dimensions, Linking, NativeModules, Appearance, useColorScheme,
};
