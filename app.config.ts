import "dotenv/config";

export default {
  expo: {
    name: "FundMind",
    slug: "fundmind",
    scheme: "fundmind",
    version: "0.1.0",
    orientation: "portrait",
    userInterfaceStyle: "automatic",
    icon: "./assets/icon.png",
    splash: { image: "./assets/splash.png", resizeMode: "contain", backgroundColor: "#ffffff" },
    ios: {
      supportsTablet: true,
      bundleIdentifier: "com.fundmind.app",
      infoPlist: {
        UIBackgroundModes: ["remote-notification"],
        NSCameraUsageDescription: "We use camera for document OCR scanning."
      }
    },
    android: {
      package: "com.fundmind.app",
      adaptiveIcon: { foregroundImage: "./assets/adaptive-icon.png", backgroundColor: "#ffffff" },
      permissions: ["CAMERA", "VIBRATE", "POST_NOTIFICATIONS"],
      useNextNotificationsApi: true
    },
    extra: { eas: { projectId: "00000000-0000-0000-0000-000000000000" } },
    plugins: [
      "expo-router",
      ["expo-notifications", { "sounds": [] }],
      "expo-sqlite",
      "expo-localization"
    ]
  }
};