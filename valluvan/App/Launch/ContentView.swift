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
import NaturalLanguage

//Data Models
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

//ContentView
struct ContentView: View {
    //State Variables
    @State private var selectedPal: String
    @State private var iyals: [String] = []
    @State private var showLanguageSettings = false
    @State private var selectedLanguage = LanguageSettingsView.languages[0].key
    @State private var isExpanded: Bool = false
    @State private var iyal: String = ""

    @State private var searchText = ""
    @State private var searchResults: [DatabaseSearchResult] = []
    @State private var isShowingSearchResults = false
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
    @State private var shouldNavigateToContentView = false

    @State private var isSearchResultsReady = false
    @State private var originalSearchText = ""

    //Initialization
    init() {
        let initialPal = LanguageUtil.getCurrentTitle(0, for: "Tamil")
        _selectedPal = State(initialValue: initialPal)
        setupAudioSession()
    }

    //View Body
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Search Bar
                    SearchBarView(
                        searchText: $searchText,
                        isSearching: $isSearching,
                        searchResults: $searchResults,
                        isShowingSearchResults: $isShowingSearchResults,
                        performSearch: performSearch
                    )

                    Divider()

                    // Main Content
                    MainContentView(
                        iyals: iyals,
                        selectedLanguage: selectedLanguage,
                        translatedIyals: translatedIyals,
                        appState: _appState
                    )

                    Divider()

                    // Bottom Bar
                    BottomBarView(selectedPal: $selectedPal, selectedLanguage: selectedLanguage)
                }
            }
            .navigationBarTitle("Valluvan", displayMode: .inline)
            .navigationBarItems(leading: leadingBarItems, trailing: trailingBarItems)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .onAppear(perform: onAppearActions)
        .onChange(of: selectedPal) { _, _ in
            Task { await loadIyals() }
        }
        .onChange(of: selectedLanguage) { _, _ in
            updateSelectedPal()
            translateIyals()
        }
        .onChange(of: shouldNavigateToContentView) { _, newValue in
            if newValue { shouldNavigateToContentView = false }
        }
        // Sheets
        .sheet(isPresented: $isShowingSearchResults) {
            if isSearchResultsReady {
                searchResultsSheet()
            } else {
                ProgressView("Loading results...")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isSearchResultsReady = true
                        }
                    }
            }
        }
        .sheet(item: $selectedSearchResult, content: explanationSheet)
        .sheet(isPresented: $showFavorites, content: favoritesSheet)
        .sheet(isPresented: $showGoToKural, content: goToKuralSheet)
        .sheet(isPresented: $showLanguageSettings, content: languageSettingsSheet)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await handleAppBecomeActive() }
        }
        .sheet(isPresented: $showExplanationView, content: explanationViewSheet)
        // Background Tasks and Notifications
        .task { await loadIyalsTask() }
    }

    //Private Methods

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

    private func getCurrentTitle(_ index: Int) -> String {
        LanguageUtil.getCurrentTitle(index, for: selectedLanguage)
    }

    private func getCurrentEnglishTitle(_ index: Int) -> String {
        LanguageUtil.getCurrentTitle(index, for: "English")
    }

    private func updateSelectedPal() {
        if let index = LanguageUtil.tamilTitle.firstIndex(of: selectedPal) {
            selectedPal = getCurrentTitle(index)
        } else {
            selectedPal = getCurrentTitle(0)
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            resetSearch()
            return
        }

        isSearching = true
        isSearchResultsReady = false

        originalSearchText = searchText
        searchText = searchText.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ").inverted).joined()
        let words = searchText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        let searchQuery = prepareSearchQuery(from: words)
        print(searchQuery)
        DispatchQueue.global(qos: .userInitiated).async {
            let results = selectedLanguage == "Tamil" ?
            searchTamilContent(query: searchQuery) :
            searchContent(query: searchQuery)

            if results.isEmpty {
                showNoResultsAlert(for: originalSearchText)
            }

            DispatchQueue.main.async {
                updateSearchResults(with: results)
            }
        }
    }

    private func prepareSearchQuery(from words: [String]) -> String {
        guard words.count > 1 else { return searchText }

        let specialWord: String = firstWordsOfTypes(from:searchText)

        return specialWord == "" ? words.shuffled().prefix(min(3, words.count))[0] :specialWord
    }
    
   private func firstWordsOfTypes(from sentence: String) -> String {
        let tagger = NSLinguisticTagger(tagSchemes: [.lexicalClass], options: 0)
        tagger.string = sentence

        var firstAdjective: String?
        var firstNoun: String?
        var adjNoun: String = ""

        tagger.enumerateTags(in: NSRange(location: 0, length: sentence.utf16.count), unit: .word, scheme: .lexicalClass) { tag, tokenRange, stop in
            let range = Range(tokenRange, in: sentence)!
            let word = String(sentence[range])

            if firstAdjective == nil, tag == .adjective {
                firstAdjective = word
            } else if firstNoun == nil, tag == .noun {
                firstNoun = word
            }

            if firstAdjective != nil || firstNoun != nil  {
                adjNoun = word
                stop.pointee = true // Stop enumeration
            }
        }

        return adjNoun
    }

    private func resetSearch() {
        searchResults = []
        isShowingSearchResults = false
        isSearchResultsReady = false
    }

    private func showNoResultsAlert(for searchText: String) {
        let alert = UIAlertController(title: "No Results", message: "No kural, found for '\(searchText)'", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func updateSearchResults(with results: [DatabaseSearchResult]) {
        searchResults = results
        isSearching = false
        hasSearched = true
        isShowingSearchResults = !results.isEmpty

        // Add a small delay before setting isSearchResultsReady to true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSearchResultsReady = true
        }
    }

    private func searchContent(query: String) -> [DatabaseSearchResult] {
        DatabaseManager.shared.searchContent(query: query, language: selectedLanguage).map { dbResult in
            DatabaseSearchResult(
                heading: dbResult.heading,
                subheading: dbResult.subheading,
                content: dbResult.content,
                explanation: dbResult.explanation,
                kuralId: dbResult.kuralId
            )
        }
    }

    private func searchTamilContent(query: String) -> [DatabaseSearchResult] {
        DatabaseManager.shared.searchTamilContent(query: query).map { dbResult in
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
        guard let data = UserDefaults.standard.data(forKey: "favorites"),
              let favorites = try? JSONDecoder().decode([Favorite].self, from: data) else { return [] }
        return favorites
    }

    private func goToKural() {
        guard let kuralId = Int(goToKuralId), (1...1330).contains(kuralId) else {
            showGoToKural = false
            return
        }

        if let result = DatabaseManager.shared.getKuralById(kuralId, language: selectedLanguage) {
            selectedSearchResult = DatabaseSearchResult(
                heading: result.heading,
                subheading: result.subheading,
                content: result.content,
                explanation: result.explanation,
                kuralId: result.kuralId
            )
        }

        showGoToKural = false
    }

    private func getSystemImage(for index: Int) -> String {
        switch index {
        case 0: return "peacesign"
        case 1: return "dollarsign.circle"
        case 2: return "heart.circle"
        default: return "\(index + 1).circle"
        }
    }

    private func toggleLanguage() {
        selectedLanguage = selectedLanguage == "Tamil" ? "English" : "Tamil"
        selectedPal = LanguageUtil.getCurrentTitle(0, for: selectedLanguage)
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
                    DispatchQueue.main.async { self.translatedIyals[iyal] = translated }
                } catch {
                    print("Error translating iyal: \(error)")
                    DispatchQueue.main.async { self.translatedIyals[iyal] = iyal }
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

    private func onAppearActions() {
        Task { await loadIyals() }
        setupSiriShortcut()
    }

    private func handleAppBecomeActive() async {
        guard let kuralId = notificationKuralId.wrappedValue,
              let result = DatabaseManager.shared.getKuralById(kuralId, language: selectedLanguage) else { return }

        await MainActor.run {
            selectedSearchResult = result
            showExplanationView = true
            notificationKuralId.wrappedValue = nil
        }
    }

    @Sendable
    private func loadIyalsTask() async {
        await loadIyals()
    }

    private func loadIyals() async {
        iyals = await DatabaseManager.shared.getIyals(for: selectedPal, language: selectedLanguage)
        if iyals.isEmpty { iyals = ["Preface", "Domestic Virtue", "Ascetic Virtue"] }
        translateIyals()
    }

    //View Builders

    @ViewBuilder
    private var leadingBarItems: some View {
        HStack {
            Button(action: { showGoToKural = true }) {
                Image(systemName: "arrow.right.circle")
            }
            Button(action: toggleLanguage) {
                Image(systemName: selectedLanguage == "Tamil" ? "a.circle.fill":"pencil.circle.fill" )
                    .foregroundColor(.blue)
            }
        }
    }

    @ViewBuilder
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

    @ViewBuilder
    private func searchResultsSheet() -> some View {
        SearchResultsView(
            results: searchResults,
            originalSearchText: originalSearchText,
            onSelectResult: { result in
                selectedSearchResult = result
                isShowingSearchResults = false
            }
        )
        .environmentObject(appState)
    }

    @ViewBuilder
    private func explanationSheet(_ result: DatabaseSearchResult) -> some View {
        ExplanationView(
            adhigaram: result.subheading,
            adhigaramId: String((result.kuralId + 9) / 10),
            lines: [result.content],
            explanation: NSAttributedString(string: result.explanation),
            selectedLanguage: selectedLanguage,
            kuralId: result.kuralId,
            iyal: "",
            shouldNavigateToContentView: $shouldNavigateToContentView
        )
        .environmentObject(appState)
    }

    @ViewBuilder
    private func favoritesSheet() -> some View {
        FavoritesView(favorites: loadFavorites(), selectedLanguage: selectedLanguage)
            .environmentObject(appState)
    }

    @ViewBuilder
    private func goToKuralSheet() -> some View {
        GoToKuralView(isPresented: $showGoToKural, kuralId: $goToKuralId, onSubmit: goToKural)
            .environmentObject(appState)
    }

    @ViewBuilder
    private func languageSettingsSheet() -> some View {
        LanguageSettingsView(
            selectedLanguage: $selectedLanguage,
            selectedPal: $selectedPal,
            languages: LanguageSettingsView.languages.map { $0.key },
            getCurrentTitle: getCurrentTitle
        )
        .environmentObject(appState)
    }

    @ViewBuilder
    private func explanationViewSheet() -> some View {
        if let result = selectedSearchResult {
            ExplanationView(
                adhigaram: result.subheading,
                adhigaramId: String((result.kuralId + 9) / 10),
                lines: [result.content],
                explanation: NSAttributedString(string: result.explanation),
                selectedLanguage: selectedLanguage,
                kuralId: result.kuralId,
                iyal: "",
                shouldNavigateToContentView: $shouldNavigateToContentView
            )
            .environmentObject(appState)
        }
    }
}

//Preview
#Preview {
    ContentView()
}
