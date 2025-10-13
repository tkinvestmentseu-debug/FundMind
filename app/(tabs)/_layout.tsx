import React from "react";
import { Tabs } from "expo-router";
import { Ionicons, MaterialCommunityIcons } from "@expo/vector-icons";
import { useTokens } from "@/providers/theme";
export default function TabsLayout(){
  const t=useTokens();
  return (
    <Tabs screenOptions={{headerShown:false,tabBarActiveTintColor:t.tint,tabBarStyle:{height:62,paddingBottom:8,paddingTop:6,backgroundColor:t.card,borderTopColor:t.border,borderTopWidth:1}}}>
      <Tabs.Screen name="home/index" options={{ title:"Home", tabBarIcon:({color,size})=><Ionicons name="home-outline" size={size} color={color}/> }}/>
      <Tabs.Screen name="calendar/index" options={{ title:"Calendar", tabBarIcon:({color,size})=><Ionicons name="calendar-outline" size={size} color={color}/> }}/>
      <Tabs.Screen name="notifications/index" options={{ title:"Notif", tabBarIcon:({color,size})=><Ionicons name="notifications-outline" size={size} color={color}/> }}/>
      <Tabs.Screen name="settings/index" options={{ title:"Settings", tabBarIcon:({color,size})=><MaterialCommunityIcons name="cog-outline" size={size} color={color}/> }}/>
    </Tabs>
  );
}