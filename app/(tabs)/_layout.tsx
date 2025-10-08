import React from "react";
import { Tabs } from "expo-router";
import { useThemeMode, useColorTokens, getStatusBarStyle } from "../../src/providers/theme";
import { StatusBar } from "expo-status-bar";

export default function TabsLayout() {
  const { scheme } = useThemeMode();
  const t = useColorTokens();
  return (
    <>
      <StatusBar style={getStatusBarStyle(scheme)} />
      <Tabs
        screenOptions={{
          headerStyle: { backgroundColor: t.bg },
          headerTitleStyle: { color: t.text },
          headerShadowVisible: false,
          tabBarActiveTintColor: t.tint,
          tabBarInactiveTintColor: t.muted,
          tabBarStyle: { backgroundColor: t.bg, borderTopColor: t.border },
          sceneContainerStyle: { backgroundColor: t.bg },
        }}
      />
    </>
  );
}
