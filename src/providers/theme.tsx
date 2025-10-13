import React, { createContext, useContext, useMemo } from "react";
import dayjs from "dayjs";
import { useThemeStore } from "../stores/theme";
export type BgVariant = "delicate" | "business" | "minimal" | "classic";
export type ThemeMode = "light" | "dark" | "auto";
type Tokens = { mode:"light"|"dark"; bg:string; card:string; text:string; tint:string; border:string; };
const ACCENT = "#C7B8FF";
function palette(mode:"light"|"dark",v:BgVariant):Tokens{
  const isLight=mode==="light";
  const base = { delicate:isLight?"#FAFAFF":"#0E0E13", business:isLight?"#F6F7FB":"#0B0C12", minimal:isLight?"#FFFFFF":"#0A0A0A", classic:isLight?"#FDFDFE":"#0D0E12" }[v];
  return { mode, bg:base, card:isLight?"#FFFFFF":"#14151B", text:isLight?"#111116":"#F2F3F7", tint:ACCENT, border:isLight?"#E6E8EF":"#1E212B" };
}
const ThemeCtx = createContext<Tokens>(palette("light","minimal"));
export const useTokens = () => useContext(ThemeCtx);
export const ThemeProvider: React.FC<{children:React.ReactNode}> = ({children})=>{
  const { mode, variant } = useThemeStore();
  const effective: "light"|"dark" = mode==="auto" ? ((()=>{const h=dayjs().hour();return(h>=7&&h<19)?"light":"dark"})()) : (mode as any);
  const tokens = useMemo(()=>palette(effective, variant),[effective,variant]);
  return <ThemeCtx.Provider value={tokens}>{children}</ThemeCtx.Provider>;
};