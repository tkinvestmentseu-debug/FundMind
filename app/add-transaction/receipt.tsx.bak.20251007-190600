import React from "react";
import { Stack, useRouter } from "expo-router";
import SwipeBack from "../_components/SwipeBack";
import TransactionForm from "../_components/TransactionForm";

export default function Screen(){
  const router = useRouter();
  return (
    <SwipeBack>
      <>
        <Stack.Screen options={{ headerTitle: "Dodaj paragon" }} />
        <TransactionForm kind="receipt" onSaved={() => router.back()} />
      </>
    </SwipeBack>
  );
}
