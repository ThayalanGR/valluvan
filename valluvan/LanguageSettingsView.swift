import SwiftUI


struct LanguageSettingsView: View {
    @Binding var selectedLanguage: String
    @Binding var selectedPal: String
    let languages: [String] 
    let getCurrentTitle: (Int) -> String
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = true
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    // Add the languages array here
    static let languages = ["Tamil", "English", "Telugu", "Hindi", "Kannad", "French", "Arabic", "Chinese", "German", "Korean", "Malay", "Malayalam", "Polish", "Russian", "Singalam", "Swedish"]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Font Size")) {
                    Picker("Font Size", selection: $appState.fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Notifications")) {
                    Toggle("Daily Thirukkural (9 AM)", isOn: $appState.isDailyKuralEnabled)
                }
                
                Section(header: Text("Language")) {
                    ForEach(languages, id: \.self) { language in
                        Button(action: {
                            selectedLanguage = language 
                            selectedPal = getCurrentTitle(0)
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
                
                Section(header: Text("About the Developer")) {
                    HStack {
                        Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                        Text("Devaraj NS")
                        Spacer()
                        Link(destination: URL(string: "http://twitter.com/nsdevaraj")!) {
                            Image(systemName: "x.circle.fill")
                                .foregroundColor(.blue)
                        }
                        Link(destination: URL(string: "http://linkedin.com/in/nsdevaraj")!) {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                trailing: HStack {
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(isDarkMode ? .yellow : .primary)
                    }
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                }
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    } 
}
