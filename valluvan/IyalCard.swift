import SwiftUI

    struct IyalCard: View {
        let iyal: String
        let translatedIyal: String
        let selectedLanguage: String
        @Environment(\.colorScheme) var colorScheme
        @EnvironmentObject var appState: AppState

        var body: some View {
            HStack {
                Image(systemName: IyalUtils.getSystemImageForIyal(iyal))
                    .foregroundColor(.yellow)
                    .padding(.trailing, 8)
                VStack(alignment: .leading, spacing: 8) {
                    Text(translatedIyal)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
            .shadow(color: shadowColor, radius: 3, x: 0, y: 2)
            .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        }
        
        private var backgroundColor: Color {
            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        }
        
        private var shadowColor: Color {
            colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
        }
    }