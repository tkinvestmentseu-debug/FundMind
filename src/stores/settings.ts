import { create } from "zustand";
type Settings={ language:"pl"|"en"; currency:string; setLanguage:(l:"pl"|"en")=>void; setCurrency:(c:string)=>void; };
export const useSettings=create<Settings>((set)=>({ language:"pl", currency:process.env.EXPO_PUBLIC_DEFAULT_CURRENCY||"PLN", setLanguage:(language)=>set({language}), setCurrency:(currency)=>set({currency}) }));