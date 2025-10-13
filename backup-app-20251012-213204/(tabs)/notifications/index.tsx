import React from "react";
import { Pressable } from "react-native";
import { ThemedView, ThemedText, ThemedCard } from "../../ui/Themed";
import { scheduleTestNotification } from "../../providers/notifications";
import { useTranslation } from "react-i18next";
export default function NotificationsScreen(){
  const { t } = useTranslation("notifications");
  return (
    <ThemedView style={{ flex:1, padding:12 }}>
      <ThemedText style={{ fontSize:20, fontWeight:"700", marginBottom:12 }}>{t("title")}</ThemedText>
      <Pressable onPress={()=>scheduleTestNotification()}><ThemedCard><ThemedText>Schedule test notification (3s)</ThemedText></ThemedCard></Pressable>
    </ThemedView>
  );
}