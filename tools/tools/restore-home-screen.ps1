Write-Output '[09/19/2025 12:23:14] Przywracam ekran główny (premium layout)...' | Tee-Object -FilePath D:\FundMind\logs\restore-home-screen-20250919-122314.log -Append
Set-Content -Path 'D:\FundMind\app\index.tsx' -Value @'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from "react-native";
import { useRouter } from "expo-router";
import { Plus, List, Wallet, BarChart2, Target, PieChart, FileText, Zap } from "lucide-react-native";

export default function HomeScreen() {
  const router = useRouter();
  const tiles = [
    { label: "Dodaj transakcję", icon: Plus, route: "/addTransaction" },
    { label: "Transakcje", icon: List, route: "/transactions" },
    { label: "Budżet miesiąca", icon: Wallet, route: "/budget" },
    { label: "Analizy", icon: BarChart2, route: "/insights" },
    { label: "Cele", icon: Target, route: "/goals" },
    { label: "Budżety", icon: PieChart, route: "/budgets" },
    { label: "Raporty", icon: FileText, route: "/reports" },
    { label: "Szybkie podsumowanie", icon: Zap, route: "/summary" },
  ];

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.header}>FundMind</Text>
      <View style={styles.widgets}>
        <View style={styles.widget}><Text style={styles.widgetTitle}>Saldo</Text><Text style={styles.widgetValue}>— PLN</Text></View>
        <View style={styles.widget}><Text style={styles.widgetTitle}>Budżet</Text><Text style={styles.widgetValue}>ten miesiąc</Text></View>
      </View>
      <View style={styles.grid}>
        {tiles.map((t, i) => (
          <TouchableOpacity key={i} style={styles.tile} onPress={() => router.push(t.route)}>
            <t.icon size={32} color="#111" />
            <Text style={styles.label}>{t.label}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, backgroundColor: "#fff" },
  header: { fontSize: 28, fontWeight: "bold", textAlign: "center", marginBottom: 20, color: "#6c47ff" },
  widgets: { flexDirection: "row", justifyContent: "space-between", marginBottom: 20 },
  widget: { flex: 1, padding: 12, margin: 4, borderRadius: 12, backgroundColor: "#f5f7fa", shadowColor: "#000", shadowOpacity: 0.05, shadowRadius: 4 },
  widgetTitle: { fontSize: 14, color: "#555" },
  widgetValue: { fontSize: 16, fontWeight: "bold", color: "#111" },
  grid: { flexDirection: "row", flexWrap: "wrap", justifyContent: "space-between" },
  tile: { width: "30%", aspectRatio: 1, marginBottom: 12, backgroundColor: "#fff", borderRadius: 16, alignItems: "center", justifyContent: "center", shadowColor: "#000", shadowOpacity: 0.08, shadowRadius: 6 },
  label: { fontSize: 12, fontWeight: "600", textAlign: "center", marginTop: 6 },
});
'@ -Encoding UTF8
Write-Output '[09/19/2025 12:23:14] Przywrócono ekran główny premium' | Tee-Object -FilePath D:\FundMind\logs\restore-home-screen-20250919-122314.log -Append
