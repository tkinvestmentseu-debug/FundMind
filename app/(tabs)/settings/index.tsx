import React from "react";
import { Pressable, Switch } from "react-native";
import { ThemedView as View } from "../../../src/ui/Themed";

import { SafeAreaView } from "react-native-safe-area-context";
import { ThemedView, ThemedText } from "../../../src/ui/Themed";
import { useThemeMode } from "../../../src/providers/theme";
import { useSettings } from "../../../src/providers/settings";

function Row({ label, right }: { label: string; right: React.ReactNode }) {
  return (
    <View
      style={{
        paddingVertical: 12,
        paddingHorizontal: 16,
        borderBottomWidth: 1,
        borderColor: "#E6EDF2",
        flexDirection: "row",
        alignItems: "center",
        justifyContent: "space-between",
      }}
    >
      <ThemedText style={{ fontWeight: "700" }}>{label}</ThemedText>
      {right}
    </View>
  );
}

function SegButton({
  text,
  active,
  onPress,
}: {
  text: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => ({
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 10,
        borderWidth: 1,
        borderColor: active ? "#2563EB" : "#E6EDF2",
        opacity: pressed ? 0.8 : 1,
      })}
    >
      <ThemedText
        style={{ color: active ? "#2563EB" : undefined, fontWeight: active ? "700" : "400" }}
      >
        {text}
      </ThemedText>
    </Pressable>
  );
}

export default function SettingsScreen() {
  const { mode, setMode } = useThemeMode();
  const { settings, set } = useSettings();

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <ThemedView style={{ flex: 1 }}>
        <View style={{ height: 12 }} />
        {/* Motyw */}
        <Row
          label="Motyw"
          right={
            <View style={{ flexDirection: "row", gap: 8 }}>
              <SegButton text="Jasny" active={mode === "light"} onPress={() => setMode("light")} />
              <SegButton text="Ciemny" active={mode === "dark"} onPress={() => setMode("dark")} />
              <SegButton text="Auto" active={mode === "system"} onPress={() => setMode("system")} />
            </View>
          }
        />

        {/* Waluta */}
        <Row
          label="Waluta"
          right={
            <View style={{ flexDirection: "row", gap: 8 }}>
              {(["PLN", "EUR", "USD"] as const).map((c) => (
                <SegButton
                  key={c}
                  text={c}
                  active={settings.currency === c}
                  onPress={() => set("currency", c)}
                />
              ))}
            </View>
          }
        />

        {/* Powiadomienia */}
        <Row
          label="Powiadomienia"
          right={<Switch value={settings.notifications} onValueChange={(v) => set("notifications", v)} />}
        />

        {/* Blokada biometryczna */}
        <Row
          label="Blokada biometryczna"
          right={<Switch value={settings.biometrics} onValueChange={(v) => set("biometrics", v)} />}
        />

        {/* Synchronizacja tylko Wi-Fi */}
        <Row
          label="Synchronizacja tylko Wi-Fi"
          right={<Switch value={settings.wifiOnly} onValueChange={(v) => set("wifiOnly", v)} />}
        />

        {/* Język */}
        <Row
          label="Język"
          right={
            <View style={{ flexDirection: "row", gap: 8 }}>
              {(["pl", "en"] as const).map((l) => (
                <SegButton
                  key={l}
                  text={l.toUpperCase()}
                  active={settings.language === l}
                  onPress={() => set("language", l)}
                />
              ))}
            </View>
          }
        />

        {/* Analityka */}
        <Row
          label="Analityka"
          right={<Switch value={settings.analytics} onValueChange={(v) => set("analytics", v)} />}
        />
      </ThemedView>
    </SafeAreaView>
  );
}



