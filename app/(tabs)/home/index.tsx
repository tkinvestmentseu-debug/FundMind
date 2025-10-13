import React, { useRef, useState } from "react";
import PagerView from "react-native-pager-view";
import { View } from "react-native";
import { ThemedView, ThemedText, ThemedCard } from "@/ui/Themed";
import { FloatingAIAgent } from "@/components/FloatingAIAgent";
import { useTranslation } from "react-i18next";
function GridTile({ label }:{ label:string }){ return (<ThemedCard style={{ width:"30%", aspectRatio:1, justifyContent:"center", alignItems:"center", marginBottom:10 }}><ThemedText style={{ fontWeight:"600" }}>{label}</ThemedText></ThemedCard>); }
export default function Home(){
  const pager=useRef<PagerView>(null); const [page,setPage]=useState(0); const { t } = useTranslation("home");
  return (
    <ThemedView style={{ flex:1, paddingHorizontal:12, paddingTop:12 }}>
      <PagerView ref={pager} style={{ flex:1 }} initialPage={0} onPageSelected={(e)=>setPage(e.nativeEvent.position)}>
        <View key="p1" style={{ flex:1, gap:12 }}>
          <ThemedText style={{ fontSize:20, fontWeight:"700", marginBottom:8 }}>{t("title")}</ThemedText>
          <View style={{ flexDirection:"row", justifyContent:"space-between", flexWrap:"wrap" }}>{Array.from({length:9}).map((_,i)=><GridTile key={i} label={`Tile ${i+1}`}/>)}</View>
        </View>
        <View key="p2" style={{ flex:1 }}>
          <ThemedText style={{ fontSize:20, fontWeight:"700", marginBottom:8 }}>{t("title")}</ThemedText>
          <View style={{ flexDirection:"row", justifyContent:"space-between", flexWrap:"wrap" }}>{Array.from({length:6}).map((_,i)=><GridTile key={i} label={`Tile ${i+1}`}/>)}</View>
        </View>
      </PagerView>
      <FloatingAIAgent />
    </ThemedView>
  );
}