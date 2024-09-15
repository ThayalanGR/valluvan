import SwiftUI

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
            .navigationBarTitle("Search Results (\(results.count))", displayMode: .inline)
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
