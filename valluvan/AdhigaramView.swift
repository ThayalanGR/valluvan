import SwiftUI
import AVFoundation
import MediaPlayer  // Add this import

struct AdhigaramView: View {
    let iyal: String
    let selectedLanguage: String
    let translatedIyal: String
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
        .navigationBarTitle(translatedIyal, displayMode: .inline)
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
