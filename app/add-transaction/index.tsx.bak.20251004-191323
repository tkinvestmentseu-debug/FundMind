import React from "react";
import { View, Text, StyleSheet } from "react-native";
import { Stack, useRouter } from "expo-router";
import { Feather } from "@expo/vector-icons";
import GradientTile from "../_components/GradientTile";
import SwipeBack from "../_components/SwipeBack";

export default function AddTransactionMenu() {
  const router = useRouter();
  return (
    <SwipeBack>
      <>
        <Stack.Screen options={{ headerTitle: "Dodaj transakcję" }} />
        <View style={styles.container}>
          <Text style={styles.title}>Co chcesz dodać?</Text>
          <View style={styles.tiles}>
            <GradientTile
              label="Dodaj paragon"
              icon={<Feather name="camera" size={40} color="#fff" />}
              onPress={() => router.push("/add-transaction/receipt")}
            />
            <GradientTile
              label="Dodaj rachunek"
              icon={<Feather name="file-text" size={40} color="#fff" />}
              onPress={() => router.push("/add-transaction/bill")}
            />
            <GradientTile
              label="Dodaj fakturę"
              icon={<Feather name="file" size={40} color="#fff" />}
              onPress={() => router.push("/add-transaction/invoice")}
            />
          </View>
        </View>
      </>
    </SwipeBack>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#F6F8FB",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 24,
    paddingBottom: 32,
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    color: "#0F172A",
    marginBottom: 24,
    textAlign: "center",
  },
  tiles: {
    width: "100%",
    alignItems: "center",
    justifyContent: "center",
    gap: 20,
  },
});
