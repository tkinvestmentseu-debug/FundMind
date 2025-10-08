import React, { useEffect, useRef } from "react";
import { Pressable, StyleSheet, Animated, Easing } from "react-native";
import { ThemedView as View, ThemedText as Text } from "../../src/ui/Themed";

import { LinearGradient } from "expo-linear-gradient";
import { Sparkles } from "lucide-react-native";

export default function PremiumAiBanner(props: {
  disableAnimation?: boolean;
  onPress?: () => void;
}) {
  useEffect(() => {
    if (props && (props as any).disableAnimation) {
      return;
    }
    const pulseLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          toValue: 0.98,
          duration: 1200,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulse, {
          toValue: 1.0,
          duration: 1200,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
      ]),
    );
    const twinkleLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(twinkle, {
          toValue: 1,
          duration: 900,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(twinkle, {
          toValue: 0,
          duration: 900,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
      ]),
    );
    pulseLoop.start();
    twinkleLoop.start();
    return () => {
      try {
        pulseLoop.stop();
        twinkleLoop.stop();
      } catch {}
    };
  }, []);
  const fade = useRef(new Animated.Value(0)).current;
  const slide = useRef(new Animated.Value(10)).current;
  const shine = useRef(new Animated.Value(0)).current;
  const pulse = useRef(new Animated.Value(1)).current;
  const press = useRef(new Animated.Value(1)).current;
  const twinkle = useRef(new Animated.Value(0)).current;

  {
    /* FM-ANIM-START */
  }
  // Zapewnienie wartości pochodnych i pętli animacji (fade, float, shimmer)
  const translateX = (shine as any).interpolate
    ? (shine as any).interpolate({ inputRange: [0, 1], outputRange: [-120, 220] })
    : shine; // fallback

  React.useEffect(() => {
    if (props && (props as any).disableAnimation) {
      return;
    }
    // reset start
    fade.setValue(0);
    slide.setValue(10);
    shine.setValue(0);
    pulse.setValue(1);

    // wejście: fade + lekkie podbicie z dołu
    Animated.parallel([
      Animated.timing(fade, { toValue: 1, duration: 400, useNativeDriver: true }),
      Animated.spring(slide, { toValue: 0, friction: 7, useNativeDriver: true }),
    ]).start();

    // shimmer: niekończący się sweep
    const shimmer = Animated.loop(
      Animated.timing(shine, {
        toValue: 1,
        duration: 2200,
        easing: Easing.linear,
        useNativeDriver: true,
      }),
    );
    shimmer.start();

    // gentle breathing (bardzo subtelny scale)
    const breath = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          toValue: 1.02,
          duration: 1400,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(pulse, {
          toValue: 1.0,
          duration: 1400,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
      ]),
    );
    breath.start();

    return () => {
      try {
        shimmer.stop();
        breath.stop();
      } catch {}
    };
  }, []);
  {
    /* FM-ANIM-END */
  }
  useEffect(() => {
    if (props && (props as any).disableAnimation) {
      return;
    }
    Animated.parallel([
      Animated.timing(fade, { toValue: 1, duration: 600, useNativeDriver: true }),
      Animated.timing(slide, { toValue: 0, duration: 600, useNativeDriver: true }),
    ]).start();

    Animated.loop(
      Animated.timing(shine, { toValue: 1, duration: 3000, useNativeDriver: true }),
    ).start();

    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1.04, duration: 1500, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 1.0, duration: 1500, useNativeDriver: true }),
      ]),
    ).start();
  }, []);

  const onPressIn = () => {
    Animated.spring(press, { toValue: 0.95, useNativeDriver: true }).start();
  };
  const onPressOut = () => {
    Animated.spring(press, {
      toValue: 1.0,
      friction: 4,
      tension: 80,
      useNativeDriver: true,
    }).start();
  };

  return (
    <Animated.View
      needsOffscreenAlphaCompositing
      style={[{ opacity: fade, transform: [{ translateY: slide }] }]}
    >
      <Animated.View style={{ opacity: pulse }}>
        <Pressable
          onPress={props.onPress || (() => {})}
          onPressIn={onPressIn}
          onPressOut={onPressOut}
          style={[styles.container, { transform: [{ translateY: -8 }] }]}
        >
          <LinearGradient
            colors={["#9c6eff", "#cdb9ff"]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.gradient}
          >
            <Animated.View
              style={{
                transform: [
                  {
                    rotate: twinkle.interpolate({
                      inputRange: [0, 1],
                      outputRange: ["-8deg", "8deg"],
                    }),
                  },
                ],
              }}
            >
              <Sparkles
                vectorEffect="non-scaling-stroke"
                absoluteStrokeWidth
                strokeWidth={2.2}
                size={26}
                color="#FFFFFF"
                style={{ marginRight: 8 }}
              />
            </Animated.View>
            <Text style={styles.text}>FundMind AI (Premium)</Text>

            <Animated.View
              style={[styles.shine, { transform: [{ skewX: "25deg" }, { translateX }] }]}
            />
          </LinearGradient>
        </Pressable>
      </Animated.View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 20,
    overflow: "hidden",
    shadowColor: "#000000",
    shadowOpacity: 0.25,
    shadowRadius: 8,
    elevation: 5,
    marginHorizontal: 16,
    marginTop: 16,
  },
  gradient: {
    padding: 9,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
  },
  text: {
    color: "#ffffff",
    fontWeight: "bold",
    fontSize: 14,
    letterSpacing: 0.5,
  },
  shine: {
    position: "absolute",
    top: 0,
    bottom: 78,
    width: 90,
    backgroundColor: "rgba(255,255,255,0.55)",
    opacity: 0.9,
    borderRadius: 20,
  },
});
