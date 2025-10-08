import React from "react";
import { useThemeMode, useTokens } from "../../src/providers/theme";
import { Tabs } from "expo-router";
import { StatusBar } from "expo-status-bar";

export default function TabsLayout() {
  const { scheme } = useThemeMode();const { colors: t } = useTokens();return (
    <>
      <StatusBar style={(scheme === 'dark' ? 'light' : 'dark')} />
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
