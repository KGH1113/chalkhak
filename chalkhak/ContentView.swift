//
//  ContentView.swift
//  chalkhak
//
//  Created by 강구현 on 1/13/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            if authManager.isAuthenticated {
                HomeView()
            } else {
                if (
                    KeychainService.shared.retrive(key: "ACCESS_TOKEN") == nil ||
                    KeychainService.shared.retrive(key: "REFRESH_TOKEN") == nil
                ) {
                    GetStartedView()
                } else {
                    LoginView()
                }
            }
        }
        .onAppear {
            AuthService.shared.protectedRoute() { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        authManager.isAuthenticated = true
                    case .failure:
                        authManager.isAuthenticated = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
