import React, { useEffect, useState } from "react";
import {  StyleSheet, Pressable, TextInput, Alert } from "react-native";
import { ThemedView as View, ThemedText as Text, ThemedScrollView as ScrollView } from "../../src/ui/Themed";

import AsyncStorage from "@react-native-async-storage/async-storage";
import { MaterialCommunityIcons } from "@expo/vector-icons";
import { router } from "expo-router";

type Rule = { id: string; type: "daily_spend_over"; amount: number; category?: string | null; active: boolean; };
const STORAGE_KEY = "fm_rules";

export default function RulesScreen() {
  const [rules, setRules] = useState<Rule[]>([]);
  const [amount, setAmount] = useState("1000");
  const [category, setCategory] = useState("");

  useEffect(() => { (async () => {
    try { const raw = await AsyncStorage.getItem(STORAGE_KEY); if (raw) setRules(JSON.parse(raw)); } catch {}
  })(); }, []);

  const saveRules = async (next: Rule[]) => { setRules(next); try { await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)); } catch {} };

  const addRule = () => {
    const val = Number(String(amount).replace(",", "."));
    if (!isFinite(val) || val <= 0) { Alert.alert("Błąd", "Podaj poprawną kwotę progu."); return; }
    const r: Rule = { id: String(Date.now()), type: "daily_spend_over", amount: val, category: category?.trim() || null, active: true };
    saveRules([r, ...rules]); setAmount("1000"); setCategory("");
  };

  const toggleActive = (id: string) => saveRules(rules.map(r => r.id === id ? ({...r, active: !r.active}) : r));
  const removeRule  = (id: string) => saveRules(rules.filter(r => r.id !== id));

  return (
    <View style={styles.page}>
      <View style={styles.header}>
        <Pressable onPress={() => router.back()} style={styles.backBtn}><MaterialCommunityIcons name="arrow-left" size={22} /></Pressable>
        <Text style={styles.title}>Dyspozycje stałe</Text>
        <View style={{ width: 22 }} />
      </View>

      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Nowa reguła</Text>
          <Text style={styles.help}>Alert, gdy dzienne wydatki przekroczą kwotę:</Text>
          <View style={styles.row}>
            <TextInput style={styles.input} value={amount} onChangeText={setAmount} keyboardType="decimal-pad" placeholder="Kwota, np. 1000" />
            <Text style={styles.currency}>PLN</Text>
          </View>
          <TextInput style={styles.input} value={category} onChangeText={setCategory} placeholder="Kategoria (opcjonalnie)" />
          <Pressable onPress={addRule} style={styles.primary}>
            <MaterialCommunityIcons name="plus-circle-outline" size={20} color="#fff" /><Text style={styles.primaryText}>Dodaj regułę</Text>
          </Pressable>
          <Text style={styles.note}>*Integracja z powiadomieniami/analizą transakcji — do podpięcia w następnym kroku.</Text>
        </View>

        <Text style={styles.section}>Aktywne reguły</Text>
        {rules.length === 0 ? <Text style={styles.empty}>Brak zdefiniowanych reguł.</Text> :
          rules.map(r => (
            <View key={r.id} style={styles.ruleItem}>
              <MaterialCommunityIcons name="alert-decagram-outline" size={20} />
              <View style={{ flex: 1 }}>
                <Text style={styles.ruleLine}>Dzienne wydatki &gt; {r.amount.toFixed(2)} PLN {r.category ? `(${r.category})` : ""}</Text>
                <Text style={styles.ruleSub}>{r.active ? "Aktywna" : "Wstrzymana"}</Text>
              </View>
              <Pressable onPress={() => toggleActive(r.id)} style={styles.chip}><Text style={styles.chipText}>{r.active ? "Wstrzymaj" : "Wznów"}</Text></Pressable>
              <Pressable onPress={() => removeRule(r.id)} style={[styles.chip, { marginLeft: 8 }]}><Text style={styles.chipText}>Usuń</Text></Pressable>
            </View>
          ))
        }
        <View style={{ height: 24 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#F6F8FB" },
  header: { height: 52, flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 12 },
  backBtn: { padding: 6, borderRadius: 10 },
  title: { fontSize: 18, fontWeight: "800" },
  card: { backgroundColor: "#fff", borderRadius: 16, padding: 14, borderWidth: 1, borderColor: "#E8EEF5",
          shadowColor: "#000", shadowOpacity: 0.06, shadowRadius: 10, shadowOffset: { width: 0, height: 6 }, elevation: 3 },
  cardTitle: { fontSize: 16, fontWeight: "800", marginBottom: 8 },
  help: { color: "#475569", marginBottom: 8 },
  row: { flexDirection: "row", alignItems: "center", gap: 8 },
  input: { flex: 1, backgroundColor: "#F6F8FB", borderRadius: 12, paddingHorizontal: 12, paddingVertical: 10, borderWidth: 1, borderColor: "#E6EDF2", marginTop: 8 },
  currency: { marginTop: 8, fontWeight: "700" },
  primary: { marginTop: 12, backgroundColor: "#7C4DFF", borderRadius: 12, alignItems: "center", justifyContent: "center", paddingVertical: 12, flexDirection: "row", gap: 8 },
  primaryText: { color: "#fff", fontWeight: "800" },
  note: { marginTop: 8, color: "#64748B", fontSize: 12 },
  section: { marginTop: 16, marginBottom: 8, fontSize: 15, fontWeight: "800" },
  empty: { color: "#64748B" },
  ruleItem: { flexDirection: "row", alignItems: "center", gap: 10, backgroundColor: "#fff", padding: 12, borderRadius: 12, borderWidth: 1, borderColor: "#E8EEF5", marginBottom: 8 },
  ruleLine: { fontWeight: "700" },
  ruleSub: { fontSize: 12, color: "#64748B" },
  chip: { backgroundColor: "#F1F5FF", borderRadius: 999, paddingHorizontal: 10, paddingVertical: 6 },
  chipText: { color: "#0A84FF", fontWeight: "700" },
});


