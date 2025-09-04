import { Pressable, Text, StyleSheet } from 'react-native';

type Props = { title: string; onPress?: () => void };

export function Button({ title, onPress }: Props) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={({ pressed }) => [styles.btn, pressed && styles.pressed]}>
      <Text style={styles.label}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  btn:{backgroundColor:'#22c55e',paddingHorizontal:16,paddingVertical:10,borderRadius:10,alignItems:'center'},
  label:{color:'#fff',fontWeight:'600'},
  pressed:{opacity:0.8}
});
