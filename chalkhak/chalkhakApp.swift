//
//  chalkhakApp.swift
//  chalkhak
//
//  Created by 강구현 on 1/13/25.
//

import SwiftUI

@main
struct chalkhakApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
