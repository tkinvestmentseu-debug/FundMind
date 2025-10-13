import React, { useState } from "react";
import { View, Pressable } from "react-native";
import { ThemedView, ThemedText, ThemedCard } from "@/ui/Themed";
import { useTranslation } from "react-i18next";
type ViewMode="year"|"month"|"day"|"hour";
export default function Calendar(){
  const [mode,setMode]=useState<ViewMode>("month"); const { t } = useTranslation("calendar");
  const Btn=({label,val}:{label:string,val:ViewMode})=> (<Pressable onPress={()=>setMode(val)} style={{marginRight:8}}><ThemedCard><ThemedText>{label}</ThemedText></ThemedCard></Pressable>);
  return (
    <ThemedView style={{ flex:1, padding:12 }}>
      <ThemedText style={{ fontSize:20, fontWeight:"700", marginBottom:12 }}>{t("title")}</ThemedText>
      <View style={{ flexDirection:"row", marginBottom:12 }}>
        <Btn label="Year" val="year"/><Btn label="Month" val="month"/><Btn label="Day" val="day"/><Btn label="Hour" val="hour"/>
      </View>
      <ThemedCard style={{ flex:1, alignItems:"center", justifyContent:"center" }}><ThemedText>{`View: ${mode}`}</ThemedText></ThemedCard>
    </ThemedView>
  );
}