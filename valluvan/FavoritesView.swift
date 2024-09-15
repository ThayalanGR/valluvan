import SwiftUI


struct FavoritesView: View {
    @State private var favorites: [Favorite]
    let selectedLanguage: String
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFavorite: Favorite?
    @State private var showExplanation = false
    @State private var explanationText: NSAttributedString = NSAttributedString()
    @State private var shouldNavigateToContentView = false
    @EnvironmentObject var appState: AppState

    init(favorites: [Favorite], selectedLanguage: String) {
        _favorites = State(initialValue: favorites)
        self.selectedLanguage = selectedLanguage
    }

    var body: some View {
        NavigationView {
            Group {
                if favorites.isEmpty {
                    emptyFavoritesView
                } else {
                    favoritesList
                }
            }
            .navigationBarTitle("Favorite Kurals List", displayMode: .inline)
            .navigationBarItems(trailing: dismissButton)
            .sheet(item: $selectedFavorite, content: explanationSheet)
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .onChange(of: shouldNavigateToContentView, perform: handleNavigationChange)
    }

    private var emptyFavoritesView: some View {
        VStack {
            Spacer()
            Text("Favorites yet to be added")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var favoritesList: some View {
        List {
            ForEach(favorites) { favorite in
                favoriteRow(for: favorite)
            }
        }
    }

    private func favoriteRow(for favorite: Favorite) -> some View {
        VStack(alignment: .leading) {
            HStack {
                favoriteContent(favorite)
                Spacer()
                deleteButton(for: favorite)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedFavorite = favorite
            loadExplanation(for: favorite.id)
        }
    }

    private func favoriteContent(_ favorite: Favorite) -> some View {
        VStack(alignment: .leading) {
            Text(favorite.adhigaramId + ": " + favorite.adhigaram)
                .font(.headline)
            
            ForEach(favorite.lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
            }
        
            HStack {
                Spacer()
                Text("Kural: " + String(favorite.id))
                    .font(.subheadline)
            }
        }
    }

    private func deleteButton(for favorite: Favorite) -> some View {
        Button(action: {
            removeFavorite(favorite)
        }) {
            Image(systemName: "trash")
                .foregroundColor(.red)
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private var dismissButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark.circle")
                .foregroundColor(.blue)
                .font(.system(size: 16))
        }
    }

    private func explanationSheet(favorite: Favorite) -> some View {
        ExplanationView(
            adhigaram: favorite.adhigaram,
            adhigaramId: String((favorite.id + 9) / 10),
            lines: favorite.lines,
            explanation: explanationText,
            selectedLanguage: selectedLanguage,
            kuralId: favorite.id,
            iyal: "", 
            shouldNavigateToContentView: $shouldNavigateToContentView
        ).environmentObject(appState)
    }

    private func handleNavigationChange(_ newValue: Bool) {
        if newValue {
            presentationMode.wrappedValue.dismiss()
            shouldNavigateToContentView = false
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
