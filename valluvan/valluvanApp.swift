//
//  valluvanApp.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import SQLite3

@main
struct ValluvanApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
