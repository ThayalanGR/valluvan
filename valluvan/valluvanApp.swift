//
//  valluvanApp.swift
//  valluvan
//
//  Created by DevarajNS on 9/12/24.
//

import SwiftUI
import SQLite3

@main
struct valluvanApp: App {
    init() {
        insertChaptersIntoDB()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func insertChaptersIntoDB() { 
    }
}
