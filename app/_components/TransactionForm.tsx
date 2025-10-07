type TransactionFormProps = { onSaved?: () => void; kind?: TransactionKind | string };
import { SafeAreaView } from 'react-native-safe-area-context';


import React, { useState } from "react";
import { View, Text, TextInput, Image, StyleSheet, ScrollView, Pressable, Alert } from "react-native";
import * as ImagePicker from "expo-image-picker";
import { Feather } from "@expo/vector-icons";

import { addTransaction, TransactionKind } from "../_data/transactions";

export default function TransactionForm(props: TransactionFormProps) {
  const [kind, setKind] = useState<TransactionKind>(() => ("receipt" as TransactionKind));const { kind: initialKind, onSaved } = props;  const [name, setName] = useState("");
  const [amount, setAmount] = useState("");const [imageUri, setImageUri] = useState<string | null>(null);

  async function pickImage(fromCamera = false) {
    const res = fromCamera
      ? await ImagePicker.launchCameraAsync({ quality: 0.7 })
      : await ImagePicker.launchImageLibraryAsync({ quality: 0.7 });
    if (!res.canceled && res.assets.length > 0) {
      setImageUri(res.assets[0].uri);
    }
  }

  function handleSave() {
    if (!name || !amount) {
      Alert.alert("Błąd", "Wprowadź nazwę i kwotę");
      return;
    }
    addTransaction({  title: name, amount: parseFloat(amount), kind: (kind as TransactionKind), dateISO: new Date().toISOString(), imageUri  });
    onSaved?.();
  }

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', alignItems: 'stretch', padding: 20 }}>
        <View style={styles.card}>
          <Text style={styles.label}>Nazwa</Text>
          <TextInput
            style={styles.input}
            placeholder="np. Zakupy"
            value={name}
            onChangeText={setName}
          />

          <Text style={styles.label}>Kwota</Text>
          <TextInput
            style={styles.input}
            placeholder="np. 123.45"
            keyboardType="decimal-pad"
            value={amount}
            onChangeText={setAmount}
          />

          <Text style={styles.label}>Zdjęcie</Text>
          {imageUri ? (
            <Image source={{ uri: imageUri }} style={styles.image} />
          ) : (
            <Text style={styles.placeholder}>Brak zdjęcia</Text>
          )}

          <View style={styles.row}>
            <Pressable style={styles.actionBtn} onPress={() => pickImage(false)}>
              <Feather name="image" size={18} color="#7C4DFF" />
              <Text style={styles.actionText}>Galeria</Text>
            </Pressable>
            <Pressable style={styles.actionBtn} onPress={() => pickImage(true)}>
              <Feather name="camera" size={18} color="#7C4DFF" />
              <Text style={styles.actionText}>Aparat</Text>
            </Pressable>
          </View>

          <Pressable style={styles.saveBtn} onPress={handleSave}>
            <Text style={styles.saveText}>Zapisz transakcję</Text>
          </Pressable>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#F4F7FA" },
  scroll: { padding: 16 },
  card: {
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    shadowColor: "#000",
    shadowOpacity: 0.06,
    shadowOffset: { width: 0, height: 4 },
    shadowRadius: 8,
    elevation: 3
  },
  label: { fontWeight: "700", marginTop: 16, fontSize: 15, color: "#111" },
  input: {
    marginTop: 6,
    borderWidth: 1,
    borderColor: "#E6EDF2",
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    backgroundColor: "#FCFCFD"
  },
  image: { marginTop: 12, height: 160, borderRadius: 12 },
  placeholder: { marginTop: 12, color: "#999", fontSize: 13 },
  row: { flexDirection: "row", justifyContent: "space-between", marginTop: 16 },
  actionBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    borderWidth: 1,
    borderColor: "#E6EDF2",
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 14,
    backgroundColor: "#F9F9FB",
    flex: 1,
    marginHorizontal: 4
  },
  actionText: { fontWeight: "600", color: "#7C4DFF" },
  saveBtn: {
    marginTop: 24,
    backgroundColor: "#7C4DFF",
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: "center"
  },
  saveText: { color: "#fff", fontWeight: "800", fontSize: 16 }
});















