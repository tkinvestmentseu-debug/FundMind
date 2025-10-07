import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
type Props = { spent: number; limit: number };
export default function PremiumBudgetWidget({ spent, limit }: Props) {
  const pct = Math.max(0, Math.min(100, limit > 0 ? (spent / limit) * 100 : 0));
  const pctStr = `${pct.toFixed(0)}%`;
  return (
    <View style={styles.card}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>Budżet miesiąca</Text>
        <View style={styles.badge}><Text style={styles.badgeText}>{pctStr}</Text></View>
      </View>
      <Text style={styles.amount}>{spent.toFixed(2)} / {limit.toFixed(2)} PLN</Text>
      <View style={styles.progressBar}><View style={[styles.progressFill, { width: `${pct}%` }]} /></View>
      <View style={styles.footerRow}>
        <Text style={styles.subtle}>Wykorzystano</Text>
        <Text style={styles.subtle}>{pctStr}</Text>
      </View>
    </View>
  );
}
const styles = StyleSheet.create({
  card:{borderRadius:18,padding:18,marginBottom:16,backgroundColor:'#fff',borderWidth:1,borderColor:'#E6EDF2',
        shadowColor:'#000',shadowOpacity:0.08,shadowRadius:12,shadowOffset:{width:0,height:6}},
  headerRow:{flexDirection:'row',alignItems:'center',justifyContent:'space-between'},
  title:{fontSize:16,fontWeight:'800',color:'#111827'},
  badge:{paddingHorizontal:10,paddingVertical:4,borderRadius:9999,backgroundColor:'#EEF2FF'},
  badgeText:{fontSize:12,fontWeight:'700',color:'#4F46E5'},
  amount:{fontSize:22,fontWeight:'900',color:'#1E3A8A',marginTop:10,marginBottom:12},
  progressBar:{height:10,backgroundColor:'#E5E7EB',borderRadius:6,overflow:'hidden'},
  progressFill:{height:'100%',backgroundColor:'#7C3AED'},
  footerRow:{flexDirection:'row',justifyContent:'space-between',marginTop:10},
  subtle:{fontSize:12,color:'#6B7280',fontWeight:'600'}
});
