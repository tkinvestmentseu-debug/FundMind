import * as Notifications from "expo-notifications";
import { Platform } from "react-native";
import { useEffect } from "react";
export function useInitNotifications(){
  useEffect(()=>{(async()=>{
    if(Platform.OS==="android"){
      await Notifications.setNotificationChannelAsync("default",{name:"Default",importance:Notifications.AndroidImportance.DEFAULT});
    }
    const { status } = await Notifications.requestPermissionsAsync();
    if(status!=="granted") console.warn("Notifications permission not granted.");
    Notifications.setNotificationHandler({ handleNotification: async()=>({ shouldShowAlert:true, shouldPlaySound:false, shouldSetBadge:false }) });
  })();},[]);
}
export async function scheduleTestNotification(){
  await Notifications.scheduleNotificationAsync({ content:{ title:"FundMind", body:"Test notification" }, trigger:{ seconds:3 } });
}