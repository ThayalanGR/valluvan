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
    @State private var selectedPal: String = "Virtue"
    @State private var iyals: [String] = []
    @State private var showLanguageSettings = false
    @State private var selectedLanguage = "English"
    @State private var isExpanded: Bool = false
    @State private var iyal: String = ""  // Add this line to declare iyal as a state variable
    
    let tamilTitle = ["அறத்துப்பால்", "பொருட்பால்", "இன்பத்துப்பால்"]
    let englishTitle = ["Virtue", "Wealth", "Nature of Love"] 
    let languages = ["Tamil", "English", "Telugu", "Hindi", "Kannad", "French", "Arabic", "Chinese", "German", "Korean", "Malay", "Malayalam", "Polish", "Russian", "Singalam", "Swedish"]
    
    @State private var searchText = ""
    @State private var searchResults: [DatabaseSearchResult] = []
    @State private var showSearchResults = false
    @State private var selectedSearchResult: DatabaseSearchResult? 
    @State private var hasSearched = false
    
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]
    @State private var showFavorites = false // Add this line
    @AppStorage("isDarkMode") private var isDarkMode = false

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
            VStack {
                HStack {
                    PalButton(title: getCurrentTitle(0), selectedPal: $selectedPal)
                    PalButton(title: getCurrentTitle(1), selectedPal: $selectedPal)
                    PalButton(title: getCurrentTitle(2), selectedPal: $selectedPal)
                }
                List(iyals, id: \.self) { iyal in
                    NavigationLink(destination: AdhigaramView(iyal: iyal, selectedLanguage: selectedLanguage)) { 
                        Text(iyal)
                    }
                } 
                .background(Color.gray.opacity(0.2))
                
                if hasSearched {
                    Text("") 
                }
            }
            .navigationBarItems(
                leading: SearchBar(text: $searchText, onSubmit: {
                    searchContent()
                })
                    .frame(width: 200), 
                trailing: HStack {
                    Button(action: {
                        searchContent()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                    }
                    Button(action: {
                        showFavorites = true // Add this line
                    }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                    }
                    Button(action: {
                        showLanguageSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16)) 
                    }
                }
            )
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView(selectedLanguage: $selectedLanguage, selectedPal: $selectedPal, languages: languages, tamilTitle: tamilTitle)
            } 
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        isExpanded.toggle()
                    }) {
                        Text(iyal)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
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
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(favorites: loadFavorites(), selectedLanguage: selectedLanguage)
        }
    }
    
    private func getCurrentTitle(_ index: Int) -> String {
        return selectedLanguage == "Tamil" ? tamilTitle[index] : englishTitle[index]
    }
    
    private func updateSelectedPal() {
        if let index = tamilTitle.firstIndex(of: selectedPal) {
            selectedPal = getCurrentTitle(index)
        }
    }
    
    private func loadIyals() {  
        iyals = DatabaseManager.shared.getIyals(for: selectedPal, language: selectedLanguage)
    }
    
    func searchContent() {
        switch selectedLanguage {
        case "Tamil":
            searchTamilContent()
        default:
            let databaseResults = DatabaseManager.shared.searchContent(query: searchText, language: selectedLanguage)
            searchResults = databaseResults.map { dbResult in
                DatabaseSearchResult(
                    heading: dbResult.heading,
                    subheading: dbResult.subheading,
                    content: dbResult.content,
                    explanation: dbResult.explanation,
                    kuralId: dbResult.kuralId
                )
            }
            DispatchQueue.main.async {
                self.showSearchResults = true
                self.hasSearched = true
            }
        }
    }
 
    func searchTamilContent() {
        let databaseResults = DatabaseManager.shared.searchTamilContent(query: searchText)
        searchResults = databaseResults.map { dbResult in
            DatabaseSearchResult(
                heading: dbResult.heading,
                subheading: dbResult.subheading,
                content: dbResult.content,
                explanation: dbResult.explanation,
                kuralId: dbResult.kuralId
            )
        }
        DispatchQueue.main.async {
            self.showSearchResults = true
            self.hasSearched = true
        }
    }

    func performSearch() {
        // Implement your search logic here
        print("Performing search for: \(searchText)")
    }

    // Add this function to load favorites
    private func loadFavorites() -> [Favorite] {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let favorites = try? JSONDecoder().decode([Favorite].self, from: data) {
            return favorites
        }
        return []
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
                                    .buttonStyle(PlainButtonStyle()) // Add this line
                                }
                                .padding(.vertical, 4)
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
        }
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
            } else {
                player.play()
                isPlaying[adhigaramSong] = true
            }
        } else { 
            if let url = Bundle.main.url(forResource: adhigaramSong, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1 // Loop indefinitely
                    audioPlayers[adhigaramSong] = player
                    player.play()
                    isPlaying[adhigaramSong] = true
                    
                    // Set up remote control events
                    setupRemoteTransportControls()
                } catch {
                    print("Error loading audio file: \(error.localizedDescription)")
                }
            } else {
                print("Audio file not found: \(adhigaramSong).mp3") // Add this line for debugging
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
    }
    
    private func loadExplanation(for adhigaram: String, lines: [String], kuralId: Int) {
        let explanation = DatabaseManager.shared.getExplanation(for: kuralId, language: selectedLanguage)
        selectedLinePair = SelectedLinePair(adhigaram: adhigaram, lines: lines, explanation: explanation, kuralId: kuralId)
    }
     
}

struct LinePairView: View {
    let linePair: [String]
    let onTap: ([String], Int) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let parts = linePair[0].split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let kuralId = Int(parts[0]) ?? 0
        let firstLine = String(parts[1])
        let secondLine = linePair.count > 1 ? linePair[1] : ""
        
        HStack(alignment: .top, spacing: 15) {
            Text("\(kuralId)")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
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
            Spacer() // Add this to push content to the left
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity) // Add this line to make it full width
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap([firstLine, secondLine], kuralId)
        }
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
    @Binding var selectedPal: String
    
    var body: some View {
        Button(action: {
            selectedPal = title
        }) {
            Text(title)
                .padding()
                .background(selectedPal == title ? Color.blue : Color.clear)
                .foregroundColor(selectedPal == title ? .white : .blue)
                .cornerRadius(8)
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

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedPal: String
    let languages: [String]
    let tamilTitle: [String]
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Theme")) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .yellow : .orange)
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
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
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            })
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
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

    init(favorites: [Favorite], selectedLanguage: String) {
        _favorites = State(initialValue: favorites)
        self.selectedLanguage = selectedLanguage
    }

    var body: some View {
        NavigationView {
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
                        }
                    }
                    .onTapGesture {
                        selectedFavorite = favorite
                        loadExplanation(for: favorite.id)
                    }
                }
            }
            .navigationTitle("Favorites")
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
                )
            }
        }
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
