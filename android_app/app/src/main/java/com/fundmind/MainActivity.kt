
package com.fundmind

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { FundMindApp() }
    }
}

@Composable
fun FundMindApp() {
    var screen by remember { mutableStateOf("home") }
    MaterialTheme {
        Surface(modifier = Modifier.fillMaxSize()) {
            when(screen){
                "home" -> HomeScreen(onNavigate = { screen = it })
                "planner" -> PlannerScreen(onBack = { screen = "home" })
                "ai" -> AIScreen(onBack = { screen = "home" })
                "newsletter" -> NewsletterScreen(onBack = { screen = "home" })
            }
        }
    }
}

@Composable
fun HomeScreen(onNavigate: (String) -> Unit) {
    Scaffold(topBar = { CenterAlignedTopAppBar(title = { Text("FundMind") }) }) { pad ->
        Column(
            modifier = Modifier.fillMaxSize().padding(pad).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Twój Planer Finansowy + AI", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(24.dp))
            Button(onClick = { onNavigate("planner") }, modifier = Modifier.fillMaxWidth()) { Text("📒 Planer") }
            Spacer(Modifier.height(8.dp))
            Button(onClick = { onNavigate("ai") }, modifier = Modifier.fillMaxWidth()) { Text("🤖 AI Asystent") }
            Spacer(Modifier.height(8.dp))
            Button(onClick = { onNavigate("newsletter") }, modifier = Modifier.fillMaxWidth()) { Text("✉️ Newsletter") }
        }
    }
}

@Composable
fun PlannerScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = { CenterAlignedTopAppBar(title = { Text("Planer Finansowy") }) }
    ) { pad ->
        Box(modifier = Modifier.fillMaxSize().padding(pad), contentAlignment = Alignment.Center) {
            Text("Tutaj będzie planer (PDF/Notion).")
        }
    }
}

@Composable
fun AIScreen(onBack: () -> Unit) {
    Scaffold(
        topBar = { CenterAlignedTopAppBar(title = { Text("AI Asystent") }) }
    ) { pad ->
        Box(modifier = Modifier.fillMaxSize().padding(pad), contentAlignment = Alignment.Center) {
            Text("Podłącz API, aby rozmawiać o budżecie i celach.")
        }
    }
}

@Composable
fun NewsletterScreen(onBack: () -> Unit) {
    var email by remember { mutableStateOf("") }
    var info by remember { mutableStateOf("") }
    Scaffold(
        topBar = { CenterAlignedTopAppBar(title = { Text("Newsletter") }) }
    ) { pad ->
        Column(
            modifier = Modifier.fillMaxSize().padding(pad).padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            OutlinedTextField(
                value = email, onValueChange = { email = it },
                label = { Text("Adres email") }, singleLine = true, modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(12.dp))
            Button(onClick = { info = "Dziękujemy za zapis! (podłącz backend)" }, modifier = Modifier.fillMaxWidth()) {
                Text("Zapisz się")
            }
            Spacer(Modifier.height(12.dp))
            if(info.isNotEmpty()) Text(info, style = MaterialTheme.typography.bodyMedium)
        }
    }
}
