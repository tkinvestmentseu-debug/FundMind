import React from "react";
import {
  ScrollView as RNScrollView,
  Text as RNText,
  View as RNView,
  ScrollViewProps,
  TextProps,
  ViewProps,
  StyleProp,
  ViewStyle,
  TextStyle,
} from "react-native";
import { useColorTokens } from "../providers/theme";

/**
 * Themed primitives:
 * - ThemedView: variant = "screen" | "surface" | "card" | "transparent"
 * - ThemedText: dim? (muted tekst)
 * - ThemedScrollView: tło z tokenów, jak "screen"
 * Każdy komponent automatycznie reaguje na zmianę motywu.
 */

type ViewVariant = "screen" | "surface" | "card" | "transparent";

export function ThemedView(
  props: ViewProps & { variant?: ViewVariant; style?: StyleProp<ViewStyle> }
) {
  const t = useColorTokens();
  const { variant = "surface", style, ...rest } = props;

  let bg: string | undefined = undefined;
  if (variant === "screen") bg = t.bg;
  else if (variant === "surface") bg = t.bg; // możesz rozdzielić później jeśli chcesz inny odcień
  else if (variant === "card") bg = t.card;
  else if (variant === "transparent") bg = undefined;

  const styleArr = [{ backgroundColor: bg }, style] as StyleProp<ViewStyle>;
  return <RNView {...rest} style={styleArr} />;
}

export function ThemedText(
  props: TextProps & { dim?: boolean; style?: StyleProp<TextStyle> }
) {
  const t = useColorTokens();
  const { dim, style, ...rest } = props;
  const color = dim ? t.muted : t.text;
  const styleArr = [{ color }, style] as StyleProp<TextStyle>;
  // @ts-ignore RN types mixing
  return <RNText {...rest} style={styleArr} />;
}

export function ThemedScrollView(
  props: ScrollViewProps & { variant?: ViewVariant }
) {
  const t = useColorTokens();
  const { variant = "screen", contentContainerStyle, ...rest } = props;
  const bg = variant === "card" ? t.card : variant === "transparent" ? undefined : t.bg;
  const styleArr = [{ backgroundColor: bg }, contentContainerStyle] as any;
  return <RNScrollView {...rest} contentContainerStyle={styleArr} />;
}
