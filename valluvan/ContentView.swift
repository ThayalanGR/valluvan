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
    @State private var selectedPal: String = "அறத்துப்பால்"
    @State private var iyals: [String] = []
    @State private var showLanguageSettings = false
    @State private var selectedLanguage = "Tamil"
    
    let languages = ["Tamil", "English", "Telugu", "Hindi", "Kannad", "French", "Arabic", "Chinese", "German", "Korean", "Malay", "Malayalam", "Polish", "Russian", "Singalam", "Swedish"]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    PalButton(title: "அறத்துப்பால்", selectedPal: $selectedPal)
                    PalButton(title: "பொருட்பால்", selectedPal: $selectedPal)
                    PalButton(title: "இன்பத்துப்பால்", selectedPal: $selectedPal)
                }
                List(iyals, id: \.self) { iyal in
                    NavigationLink(destination: AdhigaramView(iyal: iyal)) {
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
        }
        .onAppear {
            loadIyals()
        }
        .onChange(of: selectedPal) { oldValue, newValue in
            loadIyals()
        }
    }
    
    private func loadIyals() {  
        iyals = DatabaseManager.shared.getIyals(for: selectedPal)
    }
}

struct AdhigaramView: View {
    let iyal: String
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
        adhigarams = DatabaseManager.shared.getAdhigarams(for: iyal)
    }
    
    private func loadAllLines(for adhigaram: String) {
        let lines = DatabaseManager.shared.getFirstLine(for: adhigaram)
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
        let explanation = DatabaseManager.shared.getExplanation(for: kuralId)
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
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
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
