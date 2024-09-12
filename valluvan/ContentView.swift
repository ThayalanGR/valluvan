//
//  ContentView.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI

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
                List(iyals, id: \.self) { iyal in
                    NavigationLink(destination: AdhigaramView(iyal: iyal)) {
                        Text(iyal)
                    }
                }
                .navigationTitle(selectedPal)
                
                // Bottom bar
                HStack {
                    PalButton(title: "அறத்துப்பால்", selectedPal: $selectedPal)
                    PalButton(title: "பொருட்பால்", selectedPal: $selectedPal)
                    PalButton(title: "இன்பத்துப்பால்", selectedPal: $selectedPal)
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
            }
        }
        .onAppear {
            loadIyals()
        }
        .onChange(of: selectedPal) { _ in
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
    @State private var firstLines: [String: String] = [:] // Change this line
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(adhigarams, id: \.self) { adhigaram in
                    VStack(alignment: .leading) {
                        Button(action: {
                            if expandedAdhigaram == adhigaram {
                                expandedAdhigaram = nil
                            } else {
                                expandedAdhigaram = adhigaram
                                loadFirstLine(for: adhigaram)
                            }
                        }) {
                            HStack {
                                Text(adhigaram)
                                Spacer()
                                Image(systemName: expandedAdhigaram == adhigaram ? "chevron.up" : "chevron.down")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        if expandedAdhigaram == adhigaram {
                            Text(firstLines[adhigaram] ?? "Loading...")
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
    }
    
    private func loadAdhigarams() {
        adhigarams = DatabaseManager.shared.getAdhigarams(for: iyal)
    }
    
    private func loadFirstLine(for adhigaram: String) {
        let lines = DatabaseManager.shared.getFirstLine(for: adhigaram)
        if let firstLine = lines.first {
            firstLines[adhigaram] = firstLine
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
