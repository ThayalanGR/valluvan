import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun ContentScreen(viewModel: ContentViewModel = viewModel()) {
    val selectedPal by viewModel.selectedPal.observeAsState()
    val selectedLanguage by viewModel.selectedLanguage.observeAsState()
    val iyals by viewModel.iyals.observeAsState(emptyList())
    val adhigarams by viewModel.adhigarams.observeAsState(emptyList())
    val kurals by viewModel.kurals.observeAsState(emptyList())
    val searchResults by viewModel.searchResults.observeAsState(emptyList())
    
    var showLanguageSettings by remember { mutableStateOf(false) }
    var selectedIyal by remember { mutableStateOf<String?>(null) }
    var selectedAdhigaram by remember { mutableStateOf<String?>(null) }
    var searchQuery by remember { mutableStateOf("") }

    LaunchedEffect(selectedPal, selectedLanguage) {
        viewModel.loadIyals()
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Pal buttons
        Row(modifier = Modifier.fillMaxWidth().padding(8.dp)) {
            PalButton("Virtue", selectedPal) { viewModel.setSelectedPal("Virtue") }
            PalButton("Wealth", selectedPal) { viewModel.setSelectedPal("Wealth") }
            PalButton("Love", selectedPal) { viewModel.setSelectedPal("Love") }
        }

        // Search bar
        TextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            modifier = Modifier.fillMaxWidth().padding(8.dp),
            label = { Text("Search") },
            trailingIcon = {
                IconButton(onClick = { viewModel.searchContent(searchQuery) }) {
                    Icon(Icons.Default.Search, contentDescription = "Search")
                }
            }
        )

        // Content
        when {
            searchResults.isNotEmpty() -> SearchResultsList(searchResults)
            selectedAdhigaram != null -> KuralsList(kurals)
            selectedIyal != null -> AdhigaramsList(adhigarams) { adhigaram ->
                selectedAdhigaram = adhigaram
                viewModel.loadKurals(adhigaram)
            }
            else -> IyalsList(iyals) { iyal ->
                selectedIyal = iyal
                viewModel.loadAdhigarams(iyal)
            }
        }
    }

    // Language settings dialog
    if (showLanguageSettings) {
        LanguageSettingsDialog(
            selectedLanguage = selectedLanguage ?: "English",
            onLanguageSelected = { language ->
                viewModel.setSelectedLanguage(language)
                showLanguageSettings = false
            },
            onDismiss = { showLanguageSettings = false }
        )
    }
}

@Composable
fun PalButton(title: String, selectedPal: String?, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.padding(4.dp),
        colors = ButtonDefaults.buttonColors(
            backgroundColor = if (title == selectedPal) MaterialTheme.colors.primary else MaterialTheme.colors.surface
        )
    ) {
        Text(title)
    }
}

@Composable
fun IyalsList(iyals: List<String>, onIyalSelected: (String) -> Unit) {
    LazyColumn {
        items(iyals) { iyal ->
            Text(
                text = iyal,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onIyalSelected(iyal) }
                    .padding(16.dp)
            )
        }
    }
}

@Composable
fun AdhigaramsList(adhigarams: List<String>, onAdhigaramSelected: (String) -> Unit) {
    LazyColumn {
        items(adhigarams) { adhigaram ->
            Text(
                text = adhigaram,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onAdhigaramSelected(adhigaram) }
                    .padding(16.dp)
            )
        }
    }
}

@Composable
fun KuralsList(kurals: List<List<String>>) {
    LazyColumn {
        items(kurals) { kural ->
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = kural[0], style = MaterialTheme.typography.subtitle1)
                if (kural.size > 1) {
                    Text(text = kural[1], style = MaterialTheme.typography.body1)
                }
            }
        }
    }
}

@Composable
fun SearchResultsList(results: List<SearchResult>) {
    LazyColumn {
        items(results) { result ->
            Column(modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .clickable { /* TODO: Handle search result click */ }
            ) {
                Text(text = result.heading, style = MaterialTheme.typography.h6)
                Text(text = result.subheading, style = MaterialTheme.typography.subtitle1)
                Text(text = result.content, style = MaterialTheme.typography.body1)
            }
        }
    }
}

@Composable
fun LanguageSettingsDialog(
    selectedLanguage: String,
    onLanguageSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val languages = listOf("Tamil", "English", "Telugu", "Hindi")

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Language") },
        text = {
            Column {
                languages.forEach { language ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onLanguageSelected(language) }
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = language == selectedLanguage,
                            onClick = { onLanguageSelected(language) }
                        )
                        Text(
                            text = language,
                            style = MaterialTheme.typography.body1,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}