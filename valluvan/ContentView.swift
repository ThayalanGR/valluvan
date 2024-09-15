//
//  ContentView.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import Intents
import IntentsUI


struct Chapter: Identifiable {
    let id: Int
    let title: String
    let audioPath: String
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

struct ContentView: View {
    @State private var selectedPal: String
    @State private var iyals: [String] = []
    @State private var showLanguageSettings = false
    @State private var selectedLanguage = "Tamil"
    @State private var isExpanded: Bool = false
    @State private var iyal: String = ""  
    
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
    @State private var siriShortcutProvider: INVoiceShortcutCenter?

    init() {
        // Initialize selectedPal with the first pal title
        let initialPal = LanguageUtil.getCurrentTitle(0, for: "Tamil")
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
                            if iyals.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "text.book.closed")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("Please select a chapter from the bottom bar")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                ForEach(iyals, id: \.self) { iyal in
                                    NavigationLink(destination: AdhigaramView(iyal: iyal, selectedLanguage: selectedLanguage, translatedIyal: translatedIyals[iyal] ?? iyal).environmentObject(appState)) {
                                        IyalCard(iyal: iyal, translatedIyal: translatedIyals[iyal] ?? iyal, selectedLanguage: selectedLanguage)
                                    }
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
            Task {
                await loadIyals()
                translateIyals()
            }
            setupSiriShortcut()
        }
        .onChange(of: selectedPal) { oldValue, newValue in
            Task {
                await loadIyals()
                translateIyals()
            }
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
                kuralId: result.kuralId,
                iyal: ""
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
            LanguageSettingsView(
                selectedLanguage: $selectedLanguage,
                selectedPal: $selectedPal,
                languages: LanguageSettingsView.languages,
                getCurrentTitle: getCurrentTitle
            )
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
                    kuralId: result.kuralId,
                    iyal:""
                )
                .environmentObject(appState)
            }
        }
        .task {
            iyals = await DatabaseManager.shared.getIyals(for: selectedPal, language: selectedLanguage)
        }
    }

    private func getCurrentTitle(_ index: Int) -> String {
        return LanguageUtil.getCurrentTitle(index, for: selectedLanguage)
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
                Image(systemName: "globe")
            }
        }
    }
    
    private func getCurrentEnglishTitle(_ index: Int) -> String {
        return LanguageUtil.getCurrentTitle(index, for: "English")
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
        if let index = LanguageUtil.tamilTitle.firstIndex(of: selectedPal) {
            selectedPal = getCurrentTitle(index)
        } else {
            selectedPal = getCurrentTitle(0)
        }
    }
    

    private func loadIyals() async {  
        iyals = await DatabaseManager.shared.getIyals(for: selectedPal, language: selectedLanguage)
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
            return "peacesign"
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
            selectedPal = LanguageUtil.getCurrentTitle(0, for: "English")
        case "English":
            selectedLanguage = "Tamil"
            selectedPal = LanguageUtil.getCurrentTitle(0, for: "Tamil")
        default:
            selectedLanguage = "Tamil"
            selectedPal = LanguageUtil.getCurrentTitle(0, for: "English")
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

    private func setupSiriShortcut() {
        let intent = INIntent()
        intent.suggestedInvocationPhrase = "Go to Kural"

        _ = INShortcut(intent: intent)
        siriShortcutProvider = INVoiceShortcutCenter.shared

    }

    func handleSiriGoToKural(kuralId: Int) {
        goToKuralId = String(kuralId)
        goToKural()
    }
} 

#Preview {
    ContentView()
}
