import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import * as SystemUI from 'expo-system-ui';
import { useAppStore } from '../store/app';

export default function RootLayout() {
  const theme = useAppStore(s => s.theme);
  useEffect(() => { SystemUI.setBackgroundColorAsync(theme === 'dark' ? '#0a0a0a' : '#ffffff'); }, [theme]);
  return (<>
    <StatusBar style={theme === 'dark' ? 'light' : 'dark'} />
    <Stack screenOptions={{ headerShown: false }} />
  </>);
}
