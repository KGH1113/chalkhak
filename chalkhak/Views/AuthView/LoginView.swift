//
//  LoginView.swift
//  chalkhak
//
//  Created by 강구현 on 1/13/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = ""
    @State private var isLoading = false
    @State private var isLoggedIn = false
    @State private var showPassword = false
    
    @State private var showGetStartedView = false
    @State private var showRegisterView = false
    
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // Back button
                Button(action: {
                    showGetStartedView = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .navigationDestination(isPresented: $showGetStartedView) {
                    GetStartedView()
                }
                
                // Title and subtitle
                Text("Login")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Login to start using Chalkhak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    TextField("Enter your email", text: $email)
                        .font(.system(size: 13))
                        .padding(.horizontal)
                        .frame(height: 44)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay {
                            // Show a border only when focused
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.systemGray), lineWidth: isEmailFocused ? 1 : 0)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isEmailFocused = true
                            }
                        }
                        .focused($isEmailFocused)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                // Password with toggle show/hide
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        if showPassword {
                            TextField("Enter password", text: $password)
                                .autocapitalization(.none)
                                .font(.system(size: 13))
                        } else {
                            SecureField("Enter password", text: $password)
                                .autocapitalization(.none)
                                .font(.system(size: 13))
                        }
                        // Eye icon toggle password visibility
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay {
                        // Show a border only when focused
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor.systemGray), lineWidth: isPasswordFocused ? 1 : 0)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isPasswordFocused = true
                        }
                    }
                    .focused($isPasswordFocused)
                }
                
                // Login in button
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.primary.opacity(0.8))
                            .cornerRadius(8)
                    } else {
                        Text("Login")
                            .font(.headline)
                            .foregroundStyle(Color(UIColor.systemBackground))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.primary.opacity(0.8))
                            .cornerRadius(8)
                    }
                }
                .navigationDestination(isPresented: $isLoggedIn) {
                    HomeView()
                }
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 40)
                        .font(.system(size: 12))
                }
                
                // Footer: Register
                VStack(alignment: .center) {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(Color(UIColor.systemGray))
                        Button(action: {
                            showRegisterView = true
                        }) {
                            Text("Register")
                                .underline()
                                .foregroundStyle(Color(UIColor.label))
                        }
                        .navigationDestination(isPresented: $showRegisterView) {
                            RegisterView()
                        }
                    }
                    .font(.footnote)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .navigationBarHidden(true)
        }
        .padding()
    }
    
    func login() {
        if (email.isEmpty || password.isEmpty) {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    AuthService.shared.protectedRoute() { protectedResult in }
                    self.isLoggedIn = true
                case .failure(let error):
                    switch error {
                    case .serverError(let message):
                        self.errorMessage = message
                    case .invalidURL:
                        self.errorMessage = "Invalid URL"
                    default:
                        self.errorMessage = "Unknown error"
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
