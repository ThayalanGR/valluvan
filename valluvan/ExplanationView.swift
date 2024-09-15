import SwiftUI


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