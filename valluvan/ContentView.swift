//
//  ContentView.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import AVFoundation
import MediaPlayer

// Move the SearchResult struct definition to the top of the file, outside of any other struct
struct SearchResult: Identifiable, CustomStringConvertible {
    let id = UUID()
    let kuralId: Int
    let adhigaram: String
    let line: String
    let explanation: NSAttributedString
    
    var description: String {
        return "SearchResult(kuralId: \(kuralId), adhigaram: \(adhigaram), line: \(line), explanation: \(explanation.string))"
    }
}

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
    @State private var searchResults: [SearchResult] = []
    @State private var showSearchResults = false
    @State private var selectedSearchResult: SearchResult?
    @State private var hasSearched = false
    
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
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
                    Text("Search Results Count: \(searchResults.count)")
                        .padding()
                }
            }
            .navigationBarItems(
                leading: SearchBar(text: $searchText)
                    .frame(width: 250),
                trailing: HStack {
                    Button(action: {
                        searchContent()
                    }) {
                        Image(systemName: "magnifyingglass")
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
                adhigaram: result.adhigaram,
                lines: [result.line],
                explanation: result.explanation,
                selectedLanguage: selectedLanguage
            )
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
                SearchResult(
                    kuralId: dbResult.kuralId,
                    adhigaram: dbResult.subheading,
                    line: dbResult.content,
                    explanation: NSAttributedString(string: dbResult.explanation)
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
            SearchResult(
                kuralId: dbResult.kuralId,
                adhigaram: dbResult.subheading,
                line: dbResult.content,
                explanation: NSAttributedString(string: dbResult.explanation)
            )
        }
        DispatchQueue.main.async {
            self.showSearchResults = true
            self.hasSearched = true
        }
    }
}

struct AdhigaramView: View {
    let iyal: String
    let selectedLanguage: String // Add this line to accept selectedLanguage
    @State private var adhigarams: [String] = []
    @State private var expandedAdhigaram: String?
    @State private var allLines: [String: [[String]]] = [:]
    @State private var audioPlayers: [String: AVAudioPlayer] = [:]
    @State private var isPlaying: [String: Bool] = [:]
    @State private var selectedLinePair: SelectedLinePair?

    var body: some View {
        List {
            ForEach(adhigarams, id: \.self) { adhigaram in
                AdhigaramRowView(
                    adhigaram: adhigaram,
                    isExpanded: expandedAdhigaram == adhigaram,
                    lines: allLines[adhigaram] ?? [],
                    isPlaying: isPlaying[adhigaram] ?? false,
                    onToggleExpand: { toggleExpand(for: adhigaram) },
                    onTogglePlayPause: { togglePlayPause(for: adhigaram) },
                    onSelectLinePair: { lines, kuralId in
                        loadExplanation(for: adhigaram, lines: lines, kuralId: kuralId)
                    },
                    selectedLanguage: selectedLanguage 
                )
            }
        }
        .navigationTitle(iyal)
        .onAppear {
            loadAdhigarams()
        }
        .onDisappear {
            stopAllAudio()
        }
        .sheet(item: $selectedLinePair) { pair in
            ExplanationView(adhigaram: pair.adhigaram, lines: pair.lines, explanation: pair.explanation, selectedLanguage: selectedLanguage)
        }
    }
    
    private func loadAdhigarams() {
        adhigarams = DatabaseManager.shared.getAdhigarams(for: iyal, language: selectedLanguage)
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
    
    private func togglePlayPause(for adhigaram: String) {
        if let player = audioPlayers[adhigaram] {
            if player.isPlaying {
                player.pause()
                isPlaying[adhigaram] = false
            } else {
                player.play()
                isPlaying[adhigaram] = true
            }
        } else { 
            if let url = Bundle.main.url(forResource:adhigaram, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1 // Loop indefinitely
                    audioPlayers[adhigaram] = player
                    player.play()
                    isPlaying[adhigaram] = true
                    
                    // Set up remote control events
                    setupRemoteTransportControls()
                } catch {
                    print("Error loading audio file: \(error.localizedDescription)")
                }
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
        selectedLinePair = SelectedLinePair(adhigaram: adhigaram, lines: lines, explanation: explanation)
    }
    
    private func toggleExpand(for adhigaram: String) {
        withAnimation {
            if expandedAdhigaram == adhigaram {
                expandedAdhigaram = nil
            } else {
                expandedAdhigaram = adhigaram
                loadAllLines(for: adhigaram)
            }
        }
    }
}

struct AdhigaramRowView: View {
    let adhigaram: String
    let isExpanded: Bool
    let lines: [[String]]
    let isPlaying: Bool
    let onToggleExpand: () -> Void
    let onTogglePlayPause: () -> Void
    let onSelectLinePair: ([String], Int) -> Void
    let selectedLanguage: String  

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Show play/pause button only for Tamil
                if selectedLanguage == "Tamil" {
                    Button(action: onTogglePlayPause) {
                        Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 16)) 
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: onToggleExpand) {
                    HStack {
                        Text(adhigaram)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 16)) 
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                ExpandedAdhigaramView(
                    lines: lines,
                    isPlaying: isPlaying,
                    onTogglePlayPause: onTogglePlayPause,
                    onSelectLinePair: onSelectLinePair
                )
            }
        }
    }
}

struct ExpandedAdhigaramView: View {
    let lines: [[String]]
    let isPlaying: Bool
    let onTogglePlayPause: () -> Void
    let onSelectLinePair: ([String], Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { 
            ForEach(lines, id: \.self) { linePair in
                LinePairView(linePair: linePair, onTap: onSelectLinePair)
            }
        }
    }
}

struct LinePairView: View {
    let linePair: [String]
    let onTap: ([String], Int) -> Void

    var body: some View {
        let parts = linePair[0].split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let kuralId = Int(parts[0]) ?? 0
        let secondPart = String(parts[1])
        let secondLine = linePair.count > 1 ? linePair[1] : ""
        VStack(alignment: .leading, spacing: 4) {
            Text(secondPart)
            if linePair.count > 1 {
                Text(secondLine)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap([secondPart, secondLine], kuralId)
        }
    }
}

struct ExplanationView: View {
    let adhigaram: String
    let lines: [String]
    let explanation: NSAttributedString
    let selectedLanguage: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isSpeaking = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(adhigaram)
                        .font(.title)
                        .fontWeight(.bold)
                    
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
                    let content = """
                    \(adhigaram)
                    \(lines.joined(separator: "\n"))
                    Explanation:
                    \(explanation.string)
                    """
                    UIPasteboard.general.string = content
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

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
        }
    }
}

struct SearchResultsView: View {
    let results: [SearchResult]
    let onSelectResult: (SearchResult) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(results.indices, id: \.self) { index in
                    let result = results[index]
                    VStack(alignment: .leading) {
                        Text("\(index + 1):")
                            .font(.headline)
                        Text("Chapter: \(result.adhigaram)")
                        Text("Line: \(result.line)")
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
}

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedPal: String  // Add this line
    let languages: [String]
    let tamilTitle: [String]  // Add this line
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        if language == "Tamil" {
                            selectedPal = tamilTitle[0]  // Set to "அறத்துப்பால்"
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
            .navigationTitle("Select Language")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16)) 
            })
        }
    }
}
