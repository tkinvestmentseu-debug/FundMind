import React from "react";
import { View, ViewProps } from "react-native";
import { useColorTokens } from "../providers/theme";

export default function Card({ style, ...rest }: ViewProps) {
  const t = useColorTokens();
  return (
    <View
      {...rest}
      style={[
        {
          backgroundColor: t.card,
          borderColor: t.border,
          borderWidth: 1,
          borderRadius: 16,
          padding: 16,
          shadowOpacity: 0.08,
          shadowRadius: 8,
          shadowOffset: { width: 0, height: 4 },
        },
        // @ts-ignore RN style array
        style,
      ]}
    />
  );
}
