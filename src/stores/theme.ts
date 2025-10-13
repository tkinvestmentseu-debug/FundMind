import { create } from "zustand";
import type { ThemeMode, BgVariant } from "../providers/theme";
type ThemeState={ mode:ThemeMode; variant:BgVariant; setMode:(m:ThemeMode)=>void; setVariant:(v:BgVariant)=>void; };
export const useThemeStore=create<ThemeState>((set)=>({ mode:"auto", variant:"minimal", setMode:(mode)=>set({mode}), setVariant:(variant)=>set({variant}) }));