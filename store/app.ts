import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

type Theme = 'light' | 'dark';

type AppState = {
  hasOnboarded: boolean;
  theme: Theme;
  setOnboarded: (v?: boolean) => void;
  setTheme: (t: Theme) => void;
  toggleTheme: () => void;
};

export const useAppStore = create<AppState>()(persist((set,get)=>({
  hasOnboarded:false,
  theme:'light',
  setOnboarded:(v=true)=>set({hasOnboarded:v}),
  setTheme:(t)=>set({theme:t}),
  toggleTheme:()=>set({theme:get().theme==='light'?'dark':'light'})
}),{name:'fundmind/app',storage:createJSONStorage(()=>AsyncStorage)}));
