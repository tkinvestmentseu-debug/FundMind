import React from "react";
import "./providers/i18n";
import { ThemeProvider } from "./providers/theme";
import { Slot } from "expo-router";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { useInitNotifications } from "./providers/notifications";
export default function RootLayout(){
  useInitNotifications();
  return (<GestureHandlerRootView style={{flex:1}}><ThemeProvider><Slot/></ThemeProvider></GestureHandlerRootView>);
}