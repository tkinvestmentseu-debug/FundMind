import React, { useState } from "react";
import { View, TextInput, Pressable, FlatList } from "react-native";
import { ThemedView, ThemedText, ThemedCard } from "../ui/Themed";
type Msg={id:string;role:"user"|"assistant";text:string};
export default function AI(){
  const [messages,setMessages]=useState<Msg[]>([]); const [input,setInput]=useState("");
  async function send(){
    const userMsg:Msg={id:Date.now()+":u",role:"user",text:input}; setMessages(p=>[...p,userMsg]); setInput("");
    try{ const base=process.env.EXPO_PUBLIC_AI_BASE_URL;
      if(base){ const res=await fetch(base,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({message:userMsg.text})}); const data=await res.json(); setMessages(p=>[...p,{id:Date.now()+":a",role:"assistant",text:String(data.reply??"...")}]); }
      else{ setMessages(p=>[...p,{id:Date.now()+":a",role:"assistant",text:"AI endpoint not set. Echo: "+userMsg.text}]); }
    }catch(e:any){ setMessages(p=>[...p,{id:Date.now()+":a",role:"assistant",text:"Error: "+(e?.message||e)}]); }
  }
  return (
    <ThemedView style={{ flex:1, padding:12 }}>
      <ThemedText style={{ fontSize:20, fontWeight:"700", marginBottom:12 }}>AI</ThemedText>
      <FlatList style={{flex:1}} data={messages} keyExtractor={(m)=>m.id} renderItem={({item})=>(<ThemedCard style={{marginBottom:8,alignSelf:item.role==="user"?"flex-end":"flex-start"}}><ThemedText>{item.text}</ThemedText></ThemedCard>)}/>
      <View style={{ flexDirection:"row", gap:8, marginTop:8 }}>
        <TextInput value={input} onChangeText={setInput} placeholder="Type..." style={{ flex:1, backgroundColor:"white", padding:10, borderRadius:10 }}/>
        <Pressable onPress={send}><ThemedCard><ThemedText>Send</ThemedText></ThemedCard></Pressable>
      </View>
    </ThemedView>
  );
}