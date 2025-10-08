import React, { useRef } from "react";
import {  PanResponder, GestureResponderEvent, PanResponderGestureState } from "react-native";
import { ThemedView as View } from "../src/ui/Themed";

import { useRouter } from "expo-router";

type Props = {
  children: React.ReactNode;
  edgeWidth?: number;      // aktywacja tylko od lewej krawędzi
  trigger?: number;        // ile px przesunąć w prawo, żeby cofnąć
  velocity?: number;       // minimalna prędkość gestu
};

export default function SwipeBack({ children, edgeWidth = 30, trigger = 60, velocity = 0.3 }: Props) {
  const router = useRouter();
  const startX = useRef(0);
  const handled = useRef(false);

  const responder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponderCapture: (evt: GestureResponderEvent) => {
        startX.current = evt.nativeEvent.pageX;
        handled.current = false;
        return false;
      },
      onMoveShouldSetPanResponder: (_: GestureResponderEvent, g: PanResponderGestureState) => {
        const fromEdge = startX.current <= edgeWidth;
        return fromEdge && g.dx > 10 && Math.abs(g.dy) < 30;
      },
      onPanResponderRelease: (_: GestureResponderEvent, g: PanResponderGestureState) => {
        const fromEdge = startX.current <= edgeWidth;
        if (!handled.current && fromEdge && g.dx > trigger && Math.abs(g.vx) >= velocity) {
          handled.current = true;
          try { router.back(); } catch {}
        }
      },
      onPanResponderTerminate: () => { handled.current = false; },
      onShouldBlockNativeResponder: () => false,
    })
  ).current;

  return (
    <View {...responder.panHandlers} style={{ flex: 1 }}>
      {children}
    </View>
  );
}

