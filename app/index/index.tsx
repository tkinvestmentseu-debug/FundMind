import { SafeAreaView } from "react-native-safe-area-context";

import { TouchableOpacity } from "react-native";
import {
  ThemedView as View,
  ThemedText as Text,
  ThemedScrollView as ScrollView,
} from "../../src/ui/Themed";

import { Redirect } from "expo-router";
export default function Index() {
  return <Redirect href="/(tabs)" />;
}
