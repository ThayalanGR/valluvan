//
//  ContentView.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import AVFoundation
import MediaPlayer

struct Chapter: Identifiable {
    let id: Int
    let title: String
    let audioPath: String
}

struct ContentView: View {
    @State private var selectedPal: String
    @State private var iyals: [String] = []
    @State private var showLanguageSettings = false
    @State private var selectedLanguage = "Tamil"
    @State private var isExpanded: Bool = false
    @State private var iyal: String = ""  
    
    let tamilTitle = ["அறத்துப்பால்", "பொருட்பால்", "இன்பத்துப்பால்"]
    let englishTitle = ["Virtue", "Wealth", "Nature of Love"] 
    let teluguTitle = ["ధర్మం", "సంపద", "ప్రేమ స్వభావం"]
    let hindiTitle = ["धर्म", "धन", "प्रेम"]
    let kannadaTitle = ["ಧರ್ಮ", "సంపద", "ಪ್ರೇಮ"]
    let frenchTitle = ["Perfection", "Richesse", "Nature de l'Amour"]
    let arabicTitle = ["فضيلة", "الثروة", "طبيعة الحب"]
    let chineseTitle = ["美德", "财富", "爱的本质"]
    let germanTitle = ["Tugend", "Wealth", "Natur des Verliebens"]
    let koreanTitle = ["미덕", "재물", "사랑의 본성"]
    let malayTitle = ["Kesempurnaan", "Kekayaan", "Sifat Cinta"]
    let malayalamTitle = ["മന്നാല്‍", "പരിപാലനം", "അന്തരാളികം പ്രിയം"]
    let polishTitle = ["Dobroć", "Bogactwo", "Natura miłości"]
    let russianTitle = ["Добродетель", "Богатство", "Суть любви"]
    let singalamTitle = ["දානය", "අරමුණ", "සතුට"]
    let swedishTitle = ["Dygd", "Välst", "Kärlekens natur"]
    let languages = ["Tamil", "English", "Telugu", "Hindi", "Kannad", "French", "Arabic", "Chinese", "German", "Korean", "Malay", "Malayalam", "Polish", "Russian", "Singalam", "Swedish"]
    
    @State private var searchText = ""
    @State private var searchResults: [DatabaseSearchResult] = []
    @State private var showSearchResults = false
    @State private var selectedSearchResult: DatabaseSearchResult? 
    @State private var hasSearched = false
    
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]
    @State private var showFavorites = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showGoToKural = false
    @State private var goToKuralId = ""
    @EnvironmentObject var appState: AppState
    @State private var selectedNotificationKuralId: Int?
    @State private var showExplanationView = false
    @Environment(\.notificationKuralId) var notificationKuralId: Binding<Int?>

    @State private var isSearching = false
    @State private var translatedIyals: [String: String] = [:]

    init() {
        // Initialize selectedPal with the first pal title
        let initialPal = tamilTitle[0]
        _selectedPal = State(initialValue: initialPal)
        setupAudioSession()
    }

    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        #endif
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    searchBar
                    
                    Divider()
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(iyals, id: \.self) { iyal in
                                NavigationLink(destination: AdhigaramView(iyal: iyal, selectedLanguage: selectedLanguage, translatedIyal: translatedIyals[iyal] ?? iyal).environmentObject(appState)) {
                                    IyalCard(iyal: iyal, translatedIyal: translatedIyals[iyal] ?? iyal, selectedLanguage: selectedLanguage)
                                }
                            }
                        }
                        .padding()
                    }
                    Divider()                    
                    bottomBar
                }
            }
            .navigationBarTitle("Valluvan", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems, trailing: trailingBarItems)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .onAppear {
            loadIyals()
            translateIyals()
        }
        .onChange(of: selectedPal) { oldValue, newValue in
            loadIyals()
            translateIyals()
        }
        .onChange(of: selectedLanguage) { oldValue, newValue in
            updateSelectedPal()
            translateIyals()
        }
        .sheet(isPresented: $showSearchResults) {
            SearchResultsView(results: searchResults, onSelectResult: { result in
                selectedSearchResult = result
                showSearchResults = false
            })
            .environmentObject(appState)
        }
        .sheet(item: $selectedSearchResult) { result in
            ExplanationView(
                adhigaram: result.subheading,
        adhigaramId: String((result.kuralId + 9) / 10),
                lines: [result.content],
                explanation: NSAttributedString(string: result.explanation),
                selectedLanguage: selectedLanguage,
                kuralId: result.kuralId
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(favorites: loadFavorites(), selectedLanguage: selectedLanguage)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showGoToKural) {
            GoToKuralView(isPresented: $showGoToKural, kuralId: $goToKuralId, onSubmit: goToKural)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageSettingsView(selectedLanguage: $selectedLanguage, selectedPal: $selectedPal, languages: languages, getCurrentTitle: getCurrentTitle)
                .environmentObject(appState)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if let kuralId = notificationKuralId.wrappedValue {
                if let result = DatabaseManager.shared.getKuralById(kuralId, language: selectedLanguage) {
                    selectedSearchResult = result
                    showExplanationView = true
                }
                notificationKuralId.wrappedValue = nil
            }
        }
        .sheet(isPresented: $showExplanationView) {
            if let result = selectedSearchResult {
                ExplanationView(
                    adhigaram: result.subheading,
                    adhigaramId: String((result.kuralId + 9) / 10),
                    lines: [result.content],
                    explanation: NSAttributedString(string: result.explanation),
                    selectedLanguage: selectedLanguage,
                    kuralId: result.kuralId
                )
                .environmentObject(appState)
            }
        }
    }

    private func getCurrentTitle(_ index: Int) -> String {
        switch selectedLanguage {
        case "Tamil":
            return tamilTitle[index]
        case "English":
            return englishTitle[index]
        case "Telugu":
            return teluguTitle[index]
        case "Hindi":
            return hindiTitle[index]
        case "Kannad":
            return kannadaTitle[index]
        case "French":
            return frenchTitle[index]
        case "Arabic":
            return arabicTitle[index]
        case "Chinese":
            return chineseTitle[index]
        case "German":
            return germanTitle[index]
        case "Korean":
            return koreanTitle[index]
        case "Malay":
            return malayTitle[index]
        case "Malayalam":
            return malayalamTitle[index]
        case "Polish":
            return polishTitle[index]
        case "Russian":
            return russianTitle[index]
        case "Singalam":
            return singalamTitle[index]
        case "Swedish":
            return swedishTitle[index]
        default:
            return englishTitle[index] // Fallback to English if language is not found
        }
    }
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $searchText, onCommit: performSearch)
                .textFieldStyle(PlainTextFieldStyle())
            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    searchResults = []
                    showSearchResults = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            if isSearching {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding()
    }
    
    
    private var leadingBarItems: some View {
        HStack {
            Button(action: { showGoToKural = true }) {
                Image(systemName: "arrow.right.circle")
            }
            Button(action: toggleLanguage) {
                Image(systemName: selectedLanguage == "Tamil" ? "pencil.circle.fill" : "a.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var trailingBarItems: some View {
        HStack {
            Button(action: { showFavorites = true }) {
                Image(systemName: "star.fill")
            }
            Button(action: { showLanguageSettings = true }) {
                Image(systemName: "gearshape")
            }
        }
    }
    
    private func getCurrentEnglishTitle(_ index: Int) -> String {
        return englishTitle[index]
    }
    
    private var bottomBar: some View {
        HStack {
            ForEach(0..<3) { index in
                PalButton(
                    title: getCurrentTitle(index),
                    query: getCurrentEnglishTitle(index),
                    systemImage: getSystemImage(for: index),
                    selectedLanguage: selectedLanguage,
                    selectedPal: $selectedPal
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func updateSelectedPal() {
        if let index = tamilTitle.firstIndex(of: selectedPal) {
            selectedPal = getCurrentTitle(index)
        } else {
            selectedPal = getCurrentTitle(0)
        }
    }
    

    private func loadIyals() {  
        iyals = DatabaseManager.shared.getIyals(for: selectedPal, language: selectedLanguage)
    }
    
    func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            showSearchResults = false
            return
        }
        
        isSearching = true
        DispatchQueue.global(qos: .userInitiated).async {
            let results: [DatabaseSearchResult]
            if self.selectedLanguage == "Tamil" {
                results = self.searchTamilContent()
            } else {
                results = self.searchContent()
            }
            
            DispatchQueue.main.async {
                self.searchResults = results
                self.showSearchResults = true
                self.hasSearched = true
                self.isSearching = false
            }
        }
    }

    func searchContent() -> [DatabaseSearchResult] {
        let databaseResults = DatabaseManager.shared.searchContent(query: searchText, language: selectedLanguage)
        return databaseResults.map { dbResult in
            DatabaseSearchResult(
                heading: dbResult.heading,
                subheading: dbResult.subheading,
                content: dbResult.content,
                explanation: dbResult.explanation,
                kuralId: dbResult.kuralId
            )
        }
    }

    func searchTamilContent() -> [DatabaseSearchResult] {
        let databaseResults = DatabaseManager.shared.searchTamilContent(query: searchText)
        return databaseResults.map { dbResult in
            DatabaseSearchResult(
                heading: dbResult.heading,
                subheading: dbResult.subheading,
                content: dbResult.content,
                explanation: dbResult.explanation,
                kuralId: dbResult.kuralId
            )
        }
    }

    private func loadFavorites() -> [Favorite] {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
            return favorites
        }
        return []
    }

    private func goToKural() {
        if let kuralId = Int(goToKuralId), (1...1330).contains(kuralId) {
            let result = DatabaseManager.shared.getKuralById(kuralId, language: selectedLanguage)
            if let result = result {
                selectedSearchResult = DatabaseSearchResult(
                    heading: result.heading,
                    subheading: result.subheading,
                    content: result.content,
                    explanation: result.explanation,
                    kuralId: result.kuralId
                )
            }
        }
        showGoToKural = false
    }

    private func getSystemImage(for index: Int) -> String {
        switch index {
        case 0:
            return "person.2.circle"
        case 1:
            return "dollarsign.circle"
        case 2:
            return "heart.circle"
        default:
            return "\(index + 1).circle"
        }
    }

    private func toggleLanguage() {
        switch selectedLanguage {
        case "Tamil":
            selectedLanguage = "English"
            selectedPal = englishTitle[0]
        case "English":
            selectedLanguage = "Tamil"
            selectedPal = tamilTitle[0]
        default:
            selectedLanguage = "Tamil"
            selectedPal = englishTitle[0]
        } 
        updateSelectedPal()
    }

    private func translateIyals() {
        guard selectedLanguage != "Tamil" else {
            translatedIyals = [:]
            return
        }
        
        Task {
            for iyal in iyals {
                do {
                    let translated = try await TranslationUtil.getTranslation(for: iyal, to: selectedLanguage)
                    DispatchQueue.main.async {
                        self.translatedIyals[iyal] = translated
                    }
                } catch {
                    print("Error translating iyal: \(error)")
                    DispatchQueue.main.async {
                        self.translatedIyals[iyal] = iyal // Fallback to original text if translation fails
                    }
                }
            }
        }
    }
} 

#Preview {
    ContentView()
}

struct SelectedLinePair: Identifiable {
    let id = UUID()
    let adhigaram: String
    let lines: [String]
    let explanation: NSAttributedString
    let kuralId: Int
}

struct Favorite: Codable, Identifiable {
    let id: Int
    let adhigaram: String
    let adhigaramId: String
    let lines: [String]
}

