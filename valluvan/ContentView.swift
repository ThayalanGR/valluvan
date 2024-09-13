//
//  ContentView.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import AVFoundation // Add this import at the top of the file

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
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    PalButton(title: getCurrentTitle(0), selectedPal: $selectedPal)
                    PalButton(title: getCurrentTitle(1), selectedPal: $selectedPal)
                    PalButton(title: getCurrentTitle(2), selectedPal: $selectedPal)
                }
                List(iyals, id: \.self) { iyal in
                    NavigationLink(destination: AdhigaramView(iyal: iyal, selectedLanguage: selectedLanguage)) { // Pass selectedLanguage here
                        Text(iyal)
                    }
                } 
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
            }
            .navigationBarItems(trailing: Button(action: {
                showLanguageSettings = true
            }) {
                Image(systemName: "gearshape")
            })
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView(selectedLanguage: $selectedLanguage, languages: languages)
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
                    }
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
            ExplanationView(adhigaram: pair.adhigaram, lines: pair.lines, explanation: pair.explanation)
        }
    }
    
    private func loadAdhigarams() {
        adhigarams = DatabaseManager.shared.getAdhigarams(for: iyal, language: selectedLanguage)
    }
    
    private func loadAllLines(for adhigaram: String) {
        let lines = DatabaseManager.shared.getFirstLine(for: adhigaram, language: selectedLanguage)
        let linePairs = stride(from: 0, to: lines.count, by: 2).map {
            Array(lines[$0..<min($0+2, lines.count)])
        }
        allLines[adhigaram] = linePairs
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
                    audioPlayers[adhigaram] = player
                    player.play()
                    isPlaying[adhigaram] = true
                } catch {
                    print("Error loading audio file: \(error.localizedDescription)")
                }
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(action: onTogglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                        .foregroundColor(.blue)
                        .font(.title)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onToggleExpand) {
                    HStack {
                        Text(adhigaram)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                ForEach(lines, id: \.self) { linePair in
                    LinePairView(linePair: linePair, onTap: onSelectLinePair)
                }
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

        VStack(alignment: .leading, spacing: 4) {
            Text(secondPart)
            if linePair.count > 1 {
                Text(linePair[1])
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap([secondPart, linePair[1]], kuralId)
        }
    }
}

struct ExplanationView: View {
    let adhigaram: String
    let lines: [String]
    let explanation: String
    @Environment(\.presentationMode) var presentationMode

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
                    
                    Text("Explanation:")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text(explanation)
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
                    \(explanation)
                    """
                    UIPasteboard.general.string = content
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                        .font(.title)
                }
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
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

#Preview {
    ContentView()
}

struct SelectedLinePair: Identifiable {
    let id = UUID()
    let adhigaram: String
    let lines: [String]
    let explanation: String
}

struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    let languages: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(language)
                            Spacer()
                            if language == selectedLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Language")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
