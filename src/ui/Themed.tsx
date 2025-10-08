import React from "react";
import { ScrollView as RNScrollView, Text as RNText, View as RNView, ScrollViewProps, TextProps, ViewProps, StyleProp, ViewStyle, TextStyle } from "react-native";
import { useColorTokens } from "../providers/theme";

export function ThemedView(props: ViewProps & { variant?: "screen" | "card" | "transparent" }) {
  const t = useColorTokens();
  const { variant = "screen", style, ...rest } = props;
  const bg = variant === "card" ? t.card : variant === "transparent" ? undefined : t.bg;
  const styleArr = [{ backgroundColor: bg }, style] as StyleProp<ViewStyle>;
  return <RNView {...rest} style={styleArr} />;
}
export function ThemedText(props: TextProps & { dim?: boolean }) {
  const t = useColorTokens();
  const { dim, style, ...rest } = props;
  const styleArr = [{ color: dim ? t.muted : t.text }, style] as StyleProp<TextStyle>;
  // @ts-ignore
  return <RNText {...rest} style={styleArr} />;
}
export function ThemedScrollView(props: ScrollViewProps & { variant?: "screen" | "card" | "transparent" }) {
  const t = useColorTokens();
  const { variant = "screen", contentContainerStyle, ...rest } = props;
  const bg = variant === "card" ? t.card : variant === "transparent" ? undefined : t.bg;
  const styleArr = [{ backgroundColor: bg }, contentContainerStyle] as any;
  return <RNScrollView {...rest} contentContainerStyle={styleArr} />;
}
