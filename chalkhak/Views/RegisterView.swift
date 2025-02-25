//
//  RegisterView.swift
//  chalkhak
//
//  Created by 강구현 on 1/15/25.
//

import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var passwordAgain = ""
    
    @State private var errorMessage: String?
    
    @State private var showLoginView = false
    
    @State private var isLoading = false
    
    @State private var showHomeView: Bool = false
    
    let inputViews = ["username", "email", "phone", "password"]
    @State private var currentInputViewIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // Back button
                Button(action: {
                    showLoginView = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .navigationDestination(isPresented: $showLoginView) {
                    LoginView()
                }
                
                // Title and subtitle
                Text("Register")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("Please fill the form below to register.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 30)
                
                switch inputViews[currentInputViewIndex] {
                case "username":
                    UsernameInputView(username: $username)
                        .onChange(of: username) {
                            if (!username.isEmpty && !isValidUsername(username)) {
                                errorMessage = "Username must be between 3 and 20 characters long"
                            } else {
                                errorMessage = nil
                            }
                        }
                case "email":
                    EmailInputView(email: $email)
                        .onChange(of: email) {
                            if (!email.isEmpty && !isValidEmail(email)) {
                                errorMessage = "Please enter a valid email address"
                            } else {
                                errorMessage = nil
                            }
                        }
                case "phone":
                    PhoneInputView(phone: $phone)
                        .onChange(of: phone) {
                            if (!phone.isEmpty && !isValidPhone(phone)) {
                                errorMessage = "Invalid phone number. Please check if you included your country code"
                            } else {
                                errorMessage = nil
                            }
                        }
                case "password":
                    PasswordInputView(password: $password, passwordAgain: $passwordAgain)
                        .onChange(of: password) {
                            if (!password.isEmpty && !isValidPassword(password)) {
                                errorMessage = "Password must be at least 8 characters long"
                            } else {
                                errorMessage = nil
                            }
                        }
                        .onChange(of: passwordAgain) {
                            if (password != passwordAgain) {
                                errorMessage = "Passwords do not match"
                            } else {
                                errorMessage = nil
                            }
                        }
                default:
                    EmptyView()
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 20)
                        .font(.system(size: 12))
                } else {
                    EmptyView()
                }
                
                // Prev, Next button & Dot shaped progress viewer
                HStack(alignment: .top) {
                    Button(action: {
                        if (currentInputViewIndex <= 0) {
                            return
                        }
                        currentInputViewIndex -= 1
                    }) {
                        Text("Previous")
                            .underline()
                            .font(.footnote)
                            .foregroundStyle(Color(UIColor.label))
                    }
                    .disabled(currentInputViewIndex <= 0)
                    .opacity(currentInputViewIndex <= 0 ? 0 : 1)
                    
                    Spacer()
                    
                    ForEach(0..<inputViews.count, id: \.self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(index == currentInputViewIndex ? Color.primary : Color(UIColor.systemGray))
                            .opacity(index == currentInputViewIndex ? 1 : 0.2)
                    }
                    
                    Spacer()
                    
                    if (
                        (!username.isEmpty && !email.isEmpty && !phone.isEmpty && !password.isEmpty) &&
                        currentInputViewIndex >= inputViews.count - 1
                    ) {
                        Button(action: {
                            if errorMessage == nil {
                                register()
                            }
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 80, minHeight: 44)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            } else {
                                Text("Register")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 80, minHeight: 44)
                                    .background(Color.accentColor)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(errorMessage != nil)
                        .navigationDestination(isPresented: $showHomeView) {
                            HomeView()
                        }
                    } else {
                        Button(action: {
                            if (currentInputViewIndex >= inputViews.count - 1) {
                                return
                            }
                            currentInputViewIndex += 1
                        }) {
                            Text("Next")
                                .font(.subheadline)
                                .foregroundStyle(Color(UIColor.systemBackground))
                                .frame(minWidth: 70, minHeight: 44)
                                .background(Color.primary.opacity(0.8))
                                .cornerRadius(8)
                        }
                        .disabled(currentInputViewIndex >= inputViews.count - 1)
                        .opacity(currentInputViewIndex >= inputViews.count - 1 ? 0.3 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .onChange(of: currentInputViewIndex) {
                    switch inputViews[currentInputViewIndex] {
                    case "username":
                        if (!username.isEmpty && !isValidUsername(username)) {
                            errorMessage = "Username must be between 3 and 20 characters long"
                        } else {
                            errorMessage = nil
                        }
                    case "email":
                        if (!email.isEmpty && !isValidEmail(email)) {
                            errorMessage = "Please enter a valid email address"
                        } else {
                            errorMessage = nil
                        }
                    case "phone":
                        if (!phone.isEmpty && !isValidPhone(phone)) {
                            errorMessage = "Invalid phone number. Please check if you included your country code"
                        } else {
                            errorMessage = nil
                        }
                    case "password":
                        if (!password.isEmpty && !isValidPassword(password)) {
                            errorMessage = "Password must be at least 8 characters long"
                        } else if (password != passwordAgain) {
                            errorMessage = "Passwords do not match"
                        } else {
                            errorMessage = nil
                        }
                    default:
                        break
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .navigationBarHidden(true)
        }
        .padding()
    }
    
    func register() {
        errorMessage = nil
        isLoading = true
        
        let userData: [String: Any] = [
            "email": email,
            "username": username,
            "phone": phone,
            "password": password
        ]
        
        AuthService.shared.register(userData: userData) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                print(result)
                switch result {
                case .success(let response):
                    print("User created! ID: \(response.id), Email: \(response.email)")
                    showHomeView = true
                case .failure(let error):
                    switch error {
                    case .serverError(let message):
                        self.errorMessage = message
                    case .invalidURL:
                        self.errorMessage = "Invalid URL"
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct UsernameInputView: View {
    @Binding var username: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            TextField("Enter your unique username", text: $username)
                .font(.system(size: 13))
                .padding(.horizontal)
                .frame(height: 44)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay {
                    // Show a border only when focused
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.systemGray), lineWidth: isFocused ? 1 : 0)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
                .focused($isFocused)
                .autocapitalization(.none)
        }
    }
}

struct EmailInputView: View {
    @Binding var email: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            TextField("Enter your email address", text: $email)
                .font(.system(size: 13))
                .padding(.horizontal)
                .frame(height: 44)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay {
                    // Show a border only when focused
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.systemGray), lineWidth: isFocused ? 1 : 0)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
                .focused($isFocused)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
        }
    }
}

struct PhoneInputView: View {
    @Binding var phone: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            TextField("Enter phone number with country code", text: $phone)
                .font(.system(size: 13))
                .padding(.horizontal)
                .frame(height: 44)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay {
                    // Show a border only when focused
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.systemGray), lineWidth: isFocused ? 1 : 0)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isFocused = true
                    }
                }
                .focused($isFocused)
                .autocapitalization(.none)
                .keyboardType(.phonePad)
        }
    }
}

struct PasswordInputView: View {
    @Binding var password: String
    @Binding var passwordAgain: String
    
    @FocusState private var isPasswordFocus: Bool
    @FocusState private var isPasswordAgainFocus: Bool
    
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    .stroke(Color(UIColor.systemGray), lineWidth: isPasswordFocus ? 1 : 0)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPasswordFocus = true
                }
            }
            .focused($isPasswordFocus)
            
            Text("Confrim Password")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            HStack {
                if showPassword {
                    TextField("Enter password again to confrim", text: $passwordAgain)
                        .autocapitalization(.none)
                        .font(.system(size: 13))
                } else {
                    SecureField("Enter password again to confrim", text: $passwordAgain)
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
                    .stroke(Color(UIColor.systemGray), lineWidth: isPasswordAgainFocus ? 1 : 0)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPasswordAgainFocus = true
                }
            }
            .focused($isPasswordAgainFocus)
        }
    }
}

private func isValidUsername(_ testStr: String) -> Bool {
    return (3..<20).contains(testStr.count)
}

private func isValidEmail(_ testStr: String) -> Bool {
    let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    let predicat = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return predicat.evaluate(with: testStr)
}

private func isValidPhone(_ testStr: String) -> Bool {
    let phoneRegEx = "^\\+[1-9]\\d{1,14}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
    return predicate.evaluate(with: testStr)
}

private func isValidPassword(_ testStr: String) -> Bool {
    return testStr.count >= 8
}

#Preview {
    RegisterView()
}
