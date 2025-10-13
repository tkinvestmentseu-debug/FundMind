import React from "react";
import { Pressable } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTokens } from "../providers/theme";
import { router } from "expo-router";
export const FloatingAIAgent:React.FC=()=>{ const t=useTokens(); return (
  <Pressable onPress={()=>router.push("/ai")} style={({pressed})=>({
    position:"absolute",bottom:72,alignSelf:"center",width:62,height:62,borderRadius:31,
    backgroundColor:t.card,borderColor:t.border,borderWidth:1,opacity:pressed?0.9:1,justifyContent:"center",alignItems:"center",
    shadowColor:"#000",shadowOpacity:0.15,shadowRadius:10,shadowOffset:{width:0,height:4},elevation:3
  })}><Ionicons name="sparkles" size={24} color={t.tint}/></Pressable>
); };