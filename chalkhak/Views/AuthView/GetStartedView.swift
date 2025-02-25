//
//  GetStartedView.swift
//  chalkhak
//
//  Created by 강구현 on 1/15/25.
//

import SwiftUI

struct GetStartedView: View {
    @State private var isLoading = false
    @State private var showLoginView = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                
                // Title & Subtitle
                Text("Get Started")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Welcome to Chalkhak!\nLet's walk you through some quick steps to set up your account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                
                // Continue Button
                Button(action: {
                    showLoginView = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.primary.opacity(0.8))
                        .cornerRadius(8)
                }
                .padding(.top, 40)
                .navigationDestination(isPresented: $showLoginView) {
                    LoginView()
                }
            }
            .padding(.horizontal)
            .navigationBarHidden(true)
        }
        .padding()
    }
}

#Preview {
    GetStartedView()
}
