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
    @State private var allLines: [String: String] = [:]
    @State private var audioPlayers: [String: AVAudioPlayer] = [:] // New state for audio players
    @State private var isPlaying: [String: Bool] = [:] // New state to track playing status

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(adhigarams, id: \.self) { adhigaram in
                    VStack(alignment: .leading) {
                        HStack {
                            Button(action: {
                                togglePlayPause(for: adhigaram)
                            }) {
                                Image(systemName: isPlaying[adhigaram] ?? false ? "pause.circle" : "play.circle")
                                    .foregroundColor(.blue)
                                    .font(.title)
                            }
                            Button(action: {
                                if expandedAdhigaram == adhigaram {
                                    expandedAdhigaram = nil
                                } else {
                                    expandedAdhigaram = adhigaram
                                    loadAllLines(for: adhigaram)
                                }
                            }) {
                                HStack {
                                    Text(adhigaram)
                                    Spacer()
                                    Image(systemName: expandedAdhigaram == adhigaram ? "chevron.up" : "chevron.down")
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        if expandedAdhigaram == adhigaram {
                            Text(allLines[adhigaram] ?? "Loading...")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(iyal)
        .onAppear {
            loadAdhigarams()
        }
        .onDisappear {
            stopAllAudio()
        }
    }
    
    private func loadAdhigarams() {
        adhigarams = DatabaseManager.shared.getAdhigarams(for: iyal)
    }
    
    private func loadAllLines(for adhigaram: String) {
        let lines = DatabaseManager.shared.getFirstLine(for: adhigaram)
        let formattedLines = lines.enumerated().map { index, line in
            if (index + 1) % 2 == 0 {
                return line + "\n\n"
            } else {
                return line
            }
        }
        allLines[adhigaram] = formattedLines.joined(separator: "\n")
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
