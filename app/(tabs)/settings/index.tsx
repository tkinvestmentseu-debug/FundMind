import React from "react";
import { View, Pressable } from "react-native";
import { ThemedView, ThemedText, ThemedCard } from "@/ui/Themed";
import { useTranslation } from "react-i18next";
import { useSettings } from "@/stores/settings";
import { useThemeStore } from "@/stores/theme";
export default function Settings(){
  const { t } = useTranslation("settings");
  const { language, currency, setLanguage, setCurrency } = useSettings();
  const { mode, variant, setMode, setVariant } = useThemeStore();
  const Row:React.FC<{label:string}>=({label,children})=>(<View style={{marginBottom:12}}><ThemedText style={{marginBottom:6,fontWeight:"600"}}>{label}</ThemedText><View style={{flexDirection:"row",flexWrap:"wrap",gap:8}}>{children}</View></View>);
  const Btn:React.FC<{onPress:()=>void,active?:boolean,text:string}>=({onPress,active,text})=>(<Pressable onPress={onPress}><ThemedCard style={{paddingHorizontal:12,paddingVertical:8,opacity:active?1:0.7}}><ThemedText>{text}</ThemedText></ThemedCard></Pressable>);
  return (
    <ThemedView style={{ flex:1, padding:12 }}>
      <ThemedText style={{ fontSize:20, fontWeight:"700", marginBottom:12 }}>{t("title")}</ThemedText>
      <Row label="Language"><Btn text="PL" active={language==="pl"} onPress={()=>setLanguage("pl")}/><Btn text="EN" active={language==="en"} onPress={()=>setLanguage("en")}/></Row>
      <Row label="Theme mode"><Btn text="Auto" active={mode==="auto"} onPress={()=>setMode("auto")}/><Btn text="Light" active={mode==="light"} onPress={()=>setMode("light")}/><Btn text="Dark" active={mode==="dark"} onPress={()=>setMode("dark")}/></Row>
      <Row label="Background">{["delicate","business","minimal","classic"].map(v=>(<Btn key={v} text={v} active={variant===v} onPress={()=>setVariant(v as any)}/>))}</Row>
      <Row label="Currency">{["PLN","USD","EUR","GBP","AED"].map(c=>(<Btn key={c} text={c} active={currency===c} onPress={()=>setCurrency(c)}/>))}</Row>
    </ThemedView>
  );
}