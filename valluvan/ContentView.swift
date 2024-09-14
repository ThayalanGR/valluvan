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
    @State private var selectedPal: String = "அறத்துப்பால்"
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

    init() {
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
                                NavigationLink(destination: AdhigaramView(iyal: iyal, selectedLanguage: selectedLanguage).environmentObject(appState)) {
                                    IyalCard(iyal: iyal)
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
        }
        .onChange(of: selectedPal) { oldValue, newValue in
            loadIyals()
        }
        .onChange(of: selectedLanguage) { oldValue, newValue in
            updateSelectedPal()
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
            LanguageSettingsView(selectedLanguage: $selectedLanguage, selectedPal: $selectedPal, languages: languages, tamilTitle: tamilTitle)
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
    struct IyalCard: View {
    let iyal: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(iyal)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: 3, x: 0, y: 2)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
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
    
    private func updateSelectedPal() {
        if let index = tamilTitle.firstIndex(of: selectedPal) {
            selectedPal = getCurrentTitle(index)
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

    // Add this function to load favorites
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
            return "heart.circle"
        case 1:
            return "dollarsign.circle"
        case 2:
            return "person.2.circle"
        default:
            return "\(index + 1).circle"
        }
    }
    
    // Add this function to toggle between Tamil and English
    private func toggleLanguage() {
        if selectedLanguage == "Tamil" {
            selectedLanguage = "English"
        } else {
            selectedLanguage = "Tamil"
            selectedPal = tamilTitle[0]
        }
        updateSelectedPal()
    }
}

struct GoToKuralView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @Binding var kuralId: String
    var onSubmit: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @State private var showInvalidKuralAlert = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Kural ID (1-1330)", text: $kuralId, onCommit: {
                    validateAndSubmit()
                })
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isTextFieldFocused)

                Button("Go to Kural") {
                    validateAndSubmit()
                }
                .padding()
            }
            .navigationBarTitle("Go to Kural", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showInvalidKuralAlert) {
                Alert(
                    title: Text("Invalid Kural ID"),
                    message: Text("Please enter a valid Kural ID between 1 and 1330."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func validateAndSubmit() {
        guard let id = Int(kuralId), (1...1330).contains(id) else {
            showInvalidKuralAlert = true
            return
        }
        onSubmit()
    }
}
struct AdhigaramView: View {
    let iyal: String
    let selectedLanguage: String
    @State private var adhigarams: [String] = []
    @State private var kuralIds: [Int] = []
    @State private var adhigaramSongs: [String] = []
    @State private var expandedAdhigaram: String?
    @State private var allLines: [String: [[String]]] = [:]
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]
    @State private var isPlaying: [String: Bool] = [:]
    @State private var selectedLinePair: SelectedLinePair?
    @EnvironmentObject var appState: AppState
    @State private var currentTime: [String: TimeInterval] = [:]
    @State private var duration: [String: TimeInterval] = [:]
    @State private var timer: Timer?

    var body: some View {
        List {
            ForEach(adhigarams.indices, id: \.self) { index in
                let adhigaram = adhigarams[index]
                let kuralId = kuralIds[index]
                let adhigaramId = String((kuralId + 9)/10)
                let adhigaramSong = adhigaramSongs[index]
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 15) {
                        Text(adhigaramId)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.blue)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(adhigaram)
                                .font(.headline)
                            
                            if expandedAdhigaram == adhigaram {
                                HStack {
                                    HStack {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.blue)
                                        Text(adhigaramSong)
                                    }
                                    .font(.subheadline)
                                    Spacer()
                                    Button(action: {
                                        togglePlayPause(for: adhigaramSong)
                                    }) {
                                        Image(systemName: isPlaying[adhigaramSong] ?? false ? "pause.circle" : "play.circle")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                                
                                if isPlaying[adhigaramSong] ?? false {
                                    VStack(spacing: 5) {
                                        Slider(value: Binding(
                                            get: { self.currentTime[adhigaramSong] ?? 0 },
                                            set: { newValue in
                                                self.currentTime[adhigaramSong] = newValue
                                                if let player = self.audioPlayers[adhigaramSong] {
                                                    player.currentTime = newValue
                                                }
                                            }
                                        ), in: 0...(duration[adhigaramSong] ?? 0))
                                        .accentColor(.blue)
                                        
                                        HStack {
                                            Text(timeString(from: currentTime[adhigaramSong] ?? 0))
                                            Spacer()
                                            Text(timeString(from: duration[adhigaramSong] ?? 0))
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: expandedAdhigaram == adhigaram ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if expandedAdhigaram == adhigaram {
                            expandedAdhigaram = nil
                        } else {
                            expandedAdhigaram = adhigaram
                            loadAllLines(for: adhigaram)
                        }
                    }
                    
                    if expandedAdhigaram == adhigaram {
                        VStack(spacing: 10) {
                            ForEach(allLines[adhigaram] ?? [], id: \.self) { linePair in
                                LinePairView(
                                    linePair: linePair,
                                    onTap: { lines, kuralId in
                                        loadExplanation(for: adhigaram, lines: lines, kuralId: kuralId)
                                    }
                                )
                                .environmentObject(appState)
                            }
                        }
                        .padding(.leading, 43)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle(iyal)
        .onAppear {
            loadAdhigarams()
        }
        .onDisappear {
            stopAllAudio()
        }
        .sheet(item: $selectedLinePair) { pair in
            ExplanationView(adhigaram: pair.adhigaram, adhigaramId: String((pair.kuralId + 9) / 10), lines: pair.lines, explanation: pair.explanation, selectedLanguage: selectedLanguage, kuralId: pair.kuralId)
                .environmentObject(appState)
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }
    
    private func loadAdhigarams() {
        let (adhigarams, kuralIds, adhigaramSongs) = DatabaseManager.shared.getAdhigarams(for: iyal, language: selectedLanguage)
        self.adhigarams = adhigarams
        self.kuralIds = kuralIds
        self.adhigaramSongs = adhigaramSongs
    }
    
    private func loadAllLines(for adhigaram: String) {
        let supportedLanguages = ["English", "Tamil", "Hindi", "Telugu"]
        
        if supportedLanguages.contains(selectedLanguage) {
            let lines = DatabaseManager.shared.getFirstLine(for: adhigaram, language: selectedLanguage)
            let linePairs = stride(from: 0, to: lines.count, by: 2).map {
                Array(lines[$0..<min($0+2, lines.count)])
            }
            allLines[adhigaram] = linePairs
        } else {
            let lines = DatabaseManager.shared.getSingleLine(for: adhigaram, language: selectedLanguage)
            // Wrap each line in an array to make it a 2D array
            allLines[adhigaram] = lines.map { [$0] }
        }
    }
    
    private func togglePlayPause(for adhigaramSong: String) {
        if let player = audioPlayers[adhigaramSong] {
            if player.isPlaying {
                player.pause()
                isPlaying[adhigaramSong] = false
                timer?.invalidate()
            } else {
                player.play()
                isPlaying[adhigaramSong] = true
                startTimer(for: adhigaramSong)
            }
        } else {
            if let url = Bundle.main.url(forResource: adhigaramSong, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1 // Loop indefinitely
                    audioPlayers[adhigaramSong] = player
                    player.play()
                    isPlaying[adhigaramSong] = true
                    duration[adhigaramSong] = player.duration
                    currentTime[adhigaramSong] = 0
                    startTimer(for: adhigaramSong)
                    
                    // Set up remote control events
                    setupRemoteTransportControls()
                } catch {
                    print("Error loading audio file: \(error.localizedDescription)")
                }
            } else {
                print("Audio file not found: \(adhigaramSong).mp3")
            }
        }
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { event in
            self.resumePlayback()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { event in
            self.pausePlayback()
            return .success
        }
    }

    private func resumePlayback() {
        for (adhigaram, player) in audioPlayers {
            player.play()
            isPlaying[adhigaram] = true
        }
    }

    private func pausePlayback() {
        for (adhigaram, player) in audioPlayers {
            player.pause()
            isPlaying[adhigaram] = false
        }
    }
    
    private func stopAllAudio() {
        for player in audioPlayers.values {
            player.stop()
        }
        audioPlayers.removeAll()
        isPlaying.removeAll()
        currentTime.removeAll()
        duration.removeAll()
        timer?.invalidate()
    }
    
    private func loadExplanation(for adhigaram: String, lines: [String], kuralId: Int) {
        let explanation = DatabaseManager.shared.getExplanation(for: kuralId, language: selectedLanguage)
        selectedLinePair = SelectedLinePair(adhigaram: adhigaram, lines: lines, explanation: explanation, kuralId: kuralId)
    }
     
    private func startTimer(for adhigaramSong: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let player = audioPlayers[adhigaramSong] {
                currentTime[adhigaramSong] = player.currentTime
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct LinePairView: View {
    let linePair: [String]
    let onTap: ([String], Int) -> Void
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState

    var body: some View {
        let parts = linePair[0].split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let kuralId = Int(parts[0]) ?? 0
        let firstLine = String(parts[1])
        let secondLine = linePair.count > 1 ? linePair[1] : ""
        
        HStack(alignment: .top, spacing: 15) {
            Text("\(kuralId)")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Rectangle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(firstLine)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if !secondLine.isEmpty {
                    Text(secondLine)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap([firstLine, secondLine], kuralId)
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
}

struct ExplanationView: View {
    let adhigaram: String
    let adhigaramId: String
    let lines: [String]
    let explanation: NSAttributedString
    let selectedLanguage: String
    let kuralId: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var isSpeaking = false
    @State private var isFavorite = false
    @State private var showShareSheet = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(adhigaramId)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(adhigaram)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("Kural \(kuralId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.headline)
                    }
                    
                    if selectedLanguage != "Tamil" {
                        Text("Explanation:")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                    }
                    
                    Text(AttributedString(explanation))
                        .font(.body)
                }
                .padding()
            }
            .navigationBarItems(trailing: HStack {
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                Button(action: {
                    let content = """
                    Kural \(kuralId)
                    \(adhigaramId) \(adhigaram)
                    \(lines.joined(separator: "\n"))
                    Explanation:
                    \(explanation.string)
                    """
                    #if os(iOS)
                    UIPasteboard.general.string = content
                    #else
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    #endif
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
            })
        }
        .onAppear {
            checkIfFavorite()
        }
        .sheet(isPresented: $showShareSheet) {
            let content = """
            Kural \(kuralId)
            \(adhigaramId) \(adhigaram)
            \(lines.joined(separator: "\n"))
            Explanation:
            \(explanation.string)
            """
            ShareSheet(activityItems: [content])
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }

    private func toggleFavorite() {
        if isFavorite {
            removeFavorite()
        } else {
            addFavorite()
        }
        isFavorite.toggle()
    }

    private func checkIfFavorite() {
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            if let favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
                isFavorite = favorites.contains { $0.id == kuralId }
            }
        }
    }

    private func addFavorite() {
        let favorite = Favorite(id: kuralId, adhigaram: adhigaram, adhigaramId: adhigaramId, lines: lines)
        var favorites: [Favorite] = []
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            if let decoded = try? JSONDecoder().decode([Favorite].self, from: data) {
                favorites = decoded
            }
        }
        favorites.append(favorite)
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }

    private func removeFavorite() {
        if let data = UserDefaults.standard.data(forKey: "favorites") {
            if var favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
                favorites.removeAll { $0.id == kuralId }
                if let encoded = try? JSONEncoder().encode(favorites) {
                    UserDefaults.standard.set(encoded, forKey: "favorites")
                }
            }
        }
    }
}

struct PalButton: View {
    let title: String
    let query: String
    let systemImage: String
    let selectedLanguage: String
    @Binding var selectedPal: String
    
    var body: some View {
        Button(action: {
            selectedPal = selectedLanguage == "Tamil" ? title : query
        }) {
            VStack {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedPal == (selectedLanguage == "Tamil" ? title : query) ? .blue : .gray)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSubmit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
    }
}

struct SearchResultsView: View {
    let results: [DatabaseSearchResult]
    let onSelectResult: (DatabaseSearchResult) -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(results.indices, id: \.self) { index in
                    let result = results[index]
                    VStack(alignment: .leading) {
                        Text("\(index + 1):")
                            .font(.headline)
                        Text("Chapter: \(result.subheading)")
                        Text("Line: \(result.content)")
                    }
                    .onTapGesture {
                        onSelectResult(result)
                    }
                }
            }
            .navigationTitle("Search Results (\(results.count))")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            })
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
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

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedPal: String
    let languages: [String]
    let tamilTitle: [String]
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Font Size")) {
                    Picker("Font Size", selection: $appState.fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }


                Section(header: Text("Notifications")) {
                    Toggle("Daily Thirukkural (9 AM)", isOn: $appState.isDailyKuralEnabled)
                }
                
                Section(header: Text("Language")) {
                    ForEach(languages, id: \.self) { language in
                        Button(action: {
                            selectedLanguage = language
                            if language == "Tamil" {
                                selectedPal = tamilTitle[0]
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(language)
                                Spacer()
                                if language == selectedLanguage {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16))
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                trailing: HStack {
                    Button(action: {
                        toggleLanguage()
                    }) {
                        Image(systemName: selectedLanguage == "Tamil" ? "t.circle.fill" : "e.circle.fill")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(isDarkMode ? .yellow : .primary)
                    }
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }

    private func toggleLanguage() {
        if selectedLanguage == "Tamil" {
            selectedLanguage = "English"
        } else {
            selectedLanguage = "Tamil"
            selectedPal = tamilTitle[0]
        }
    }
}

struct Favorite: Codable, Identifiable {
    let id: Int
    let adhigaram: String
    let adhigaramId: String
    let lines: [String]
}

struct FavoritesView: View {
    @State private var favorites: [Favorite]
    let selectedLanguage: String
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFavorite: Favorite?
    @State private var showExplanation = false
    @State private var explanationText: NSAttributedString = NSAttributedString()
    @EnvironmentObject var appState: AppState

    init(favorites: [Favorite], selectedLanguage: String) {
        _favorites = State(initialValue: favorites)
        self.selectedLanguage = selectedLanguage
    }

    var body: some View {
        NavigationView {
            Group {
                if favorites.isEmpty {
                    VStack {
                        Spacer()
                        Text("Favorites yet to be added")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(favorites) { favorite in
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(favorite.adhigaram)
                                            .font(.headline)
                                        ForEach(favorite.lines, id: \.self) { line in
                                            Text(line)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        removeFavorite(favorite)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFavorite = favorite
                                loadExplanation(for: favorite.id)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Favorites List", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            })
            .sheet(item: $selectedFavorite) { favorite in
                ExplanationView(
                    adhigaram: favorite.adhigaram,
                    adhigaramId: String((favorite.id + 9) / 10),
                    lines: favorite.lines,
                    explanation: explanationText,
                    selectedLanguage: selectedLanguage,
                    kuralId: favorite.id
                ).environmentObject(appState)
            }
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }

    private func loadExplanation(for kuralId: Int) {
        explanationText = DatabaseManager.shared.getExplanation(for: kuralId, language: selectedLanguage)
        showExplanation = true
    }

    private func removeFavorite(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
