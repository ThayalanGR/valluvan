import SwiftUI


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
                    kuralId: favorite.id,
                    iyal: ""
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
