import React from "react";
import { View, Text, ScrollView, type ViewProps, type TextProps } from "react-native";
import { useTokens } from "../providers/theme";
export const ThemedView:React.FC<ViewProps>=({style,...rest})=>{ const t=useTokens(); return <View style={[{backgroundColor:t.bg},style]} {...rest}/>; };
export const ThemedCard:React.FC<ViewProps>=({style,...rest})=>{ const t=useTokens(); return <View style={[{backgroundColor:t.card,borderColor:t.border,borderWidth:1,borderRadius:14,padding:12},style]} {...rest}/>; };
export const ThemedText:React.FC<TextProps>=({style,...rest})=>{ const t=useTokens(); return <Text style={[{color:t.text},style]} {...rest}/>; };
export const ThemedScrollView:React.FC<ViewProps>=({style,...rest})=>{ const t=useTokens(); return <ScrollView style={[{backgroundColor:t.bg},style]} {...rest} /> as any; };