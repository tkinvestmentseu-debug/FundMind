import React from "react";
import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useThemeMode, useColorTokens, getStatusBarStyle } from "../src/providers/theme";
import { StatusBar } from "expo-status-bar";

export default function TabsLayout() {
  const { scheme } = useThemeMode();
  const t = useColorTokens();
  const tint = t.tint;
  const muted = t.muted;
  const bg = t.bg;
  return (
    <>
      <StatusBar style={getStatusBarStyle(scheme)} />
      <Tabs
        screenOptions={({ route }) => ({
          headerStyle: { backgroundColor: bg },
          headerTitleStyle: { color: t.text },
          headerShadowVisible: false,
          tabBarActiveTintColor: tint,
          tabBarInactiveTintColor: muted,
          tabBarStyle: { backgroundColor: bg, borderTopColor: t.border },
          tabBarIcon: ({ color, focused, size }) => {
            const s = route.name;
            const icon =
              s === "index" ? (focused ? "home" : "home-outline") :
              s === "calendar" ? (focused ? "calendar" : "calendar-outline") :
              s === "notifications/index" ? (focused ? "notifications" : "notifications-outline") :
              s === "settings/index" ? (focused ? "settings" : "settings-outline") :
              (focused ? "apps" : "apps-outline");
            return <Ionicons name={icon as any} size={size} color={color} />;
          },
          title:
            route.name === "index" ? "Start" :
            route.name === "calendar" ? "Kalendarz" :
            route.name === "notifications/index" ? "Powiadomienia" :
            route.name === "settings/index" ? "Ustawienia" :
            route.name,
        })}
      >
        <Tabs.Screen name="index" />
        <Tabs.Screen name="calendar" />
        <Tabs.Screen name="notifications/index" />
        <Tabs.Screen name="settings/index" />
      </Tabs>
    </>
  );
}

