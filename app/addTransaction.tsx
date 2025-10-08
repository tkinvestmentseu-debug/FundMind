import React, { useState } from "react";
import { StyleSheet, TextInput, Pressable, Alert, Image } from "react-native";
import { ThemedView as View, ThemedText as Text } from "src/ui/Themed";

import { Stack } from "expo-router";
import { Ionicons } from "@expo/vector-icons";

const AddTransaction: React.FC = () => {
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [photoUri, setPhotoUri] = useState<string | null>(null);

  const onSave = () => {
    Alert.alert("Zapisano", "Transakcja zostala zapisana.");
  };
  const onGallery = () => Alert.alert("Galeria", "Wybierz zdjecie z galerii.");
  const onCamera = () => Alert.alert("Aparat", "Zrob zdjecie aparatem.");

  return (
    <View style={styles.screen}>
      <Stack.Screen options={{ title: "Nowa transakcja" }} />
      <View style={styles.card}>
        <Text style={styles.label}>Nazwa</Text>
        <TextInput
          value={title}
          onChangeText={setTitle}
          placeholder="np. Zakupy"
          style={styles.input}
        />
        <Text style={styles.label}>Kwota</Text>
        <TextInput
          value={amount}
          onChangeText={setAmount}
          placeholder="np. 123.45"
          keyboardType="decimal-pad"
          style={styles.input}
        />
        <Text style={styles.label}>Zdjecie</Text>
        {photoUri ? (
          <Image source={{ uri: photoUri }} style={styles.photo} />
        ) : (
          <Text style={styles.noPhoto}>Brak zdjecia</Text>
        )}
        <View style={styles.row}>
          <Pressable onPress={onGallery} style={styles.button}>
            <Ionicons name="images-outline" size={18} />
            <Text style={styles.btnText}>Galeria</Text>
          </Pressable>
          <Pressable onPress={onCamera} style={styles.button}>
            <Ionicons name="camera-outline" size={18} />
            <Text style={styles.btnText}>Aparat</Text>
          </Pressable>
        </View>
        <Pressable onPress={onSave} style={styles.saveBtn}>
          <Text style={styles.saveText}>Zapisz transakcje</Text>
        </Pressable>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#F8FAFC",
    justifyContent: "center", // wyśrodkowanie pionowe
    alignItems: "center", // wyśrodkowanie poziome
    padding: 16,
  },
  card: {
    width: "90%",
    maxWidth: 400, // premium modal look

    borderRadius: 16,
    padding: 20,
    shadowColor: "#000",
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
  },
  label: { fontWeight: "700", marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: "#E6EDF2",
    borderRadius: 12,
    padding: 10,
    marginBottom: 16,
  },
  noPhoto: { color: "#667085", marginBottom: 8 },
  photo: { height: 100, borderRadius: 12, marginBottom: 8 },
  row: { flexDirection: "row", justifyContent: "space-between", marginBottom: 16 },
  button: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    padding: 10,
    borderWidth: 1,
    borderColor: "#E6EDF2",
    borderRadius: 12,
    marginHorizontal: 4,
  },
  btnText: { marginLeft: 6, fontWeight: "600" },
  saveBtn: {
    backgroundColor: "#7C3AED",
    padding: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  saveText: { color: "#fff", fontWeight: "700" },
});

export default AddTransaction;
