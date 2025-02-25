//
//  AddPostView.swift
//  chalkhak
//
//  Created by 강구현 on 1/18/25.
//

import SwiftUI

enum AddPostViewContent {
    case imagePicker, form
}

struct AddPostView: View {
    @Binding var tab: Tab
    
    @State private var viewContent: AddPostViewContent = .imagePicker
    
    @State private var selectedImage: UIImage = UIImage()
    
    @State private var title: String = ""
    @State private var content: String = ""
    
    @State private var errorMessage: String = ""
    
    @StateObject private var locationManager = LocationManager()
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    viewContent = .imagePicker
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(viewContent == .imagePicker ? .clear : .primary)
                }
                .frame(width: 70)
                
                Spacer()
                
                Text("Add Post")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewContent == .imagePicker {
                    Button(action: {
                        viewContent = .form
                    }) {
                        Text("Next")
                    }
                    .frame(width: 70)
                } else if viewContent == .form {
                    Button(action: {
                        uploadPost()
                    }) {
                        Text("Upload")
                    }
                    .frame(width: 70)
                    .disabled(title.isEmpty || content.isEmpty)
                    .opacity(title.isEmpty || content.isEmpty ? 0.6 : 1)
                }
            }
            .padding()
            .padding(.horizontal, 20)
            .ignoresSafeArea(.keyboard)
            
            Divider()
            
            switch viewContent {
            case .imagePicker:
                #if DEBUG
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
                    Text("Image Picker Placeholder in Preview")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ImagePickerView(selectedImage: $selectedImage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                #else
                ImagePickerView(selectedImage: $selectedImage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
            case .form:
                FormView(
                    selectedImage: selectedImage,
                    title: $title,
                    content: $content,
                    errorMessage: $errorMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    func uploadPost() {
        UploadService.shared.uploadImage(image: selectedImage) { uploadResult in
            print("upload result: \(uploadResult)")
            
            switch uploadResult {
            case .success(let url):
                print("Image uploaded successfully: \(url)")
                
                guard let currentLocation = locationManager.currentLocation else {
                    print("Current location not available.")
                    return
                }

                PostService.shared.createPost(
                    title: title,
                    content: content,
                    latitude: currentLocation.latitude,
                    longitude: currentLocation.longitude,
                    imageUrl: url
                ) { postResult in
                    print("post result: \(postResult)")
                    switch postResult {
                    case .success(()):
                        print("Post created successfully.")
                        viewContent = .imagePicker
                        tab = .map
                    case .failure(let error):
                        print("Error creating post: \(error)")
                    }
                }
            case .failure(let error):
                switch error {
                case .serverError(let message):
                    self.errorMessage = message
                case .invalidToken:
                    AuthService.shared.refreshToken() { refreshResult in
                        print("refresh result: \(refreshResult)")
                        switch refreshResult {
                        case .success(()):
                            self.uploadPost()
                        case .failure(let error):
                            switch error {
                            case .invalidRefreshToken:
                                self.errorMessage = "Your session has expired. Please log in again."
                                authManager.isAuthenticated = false
                            default:
                                self.errorMessage = "An unknown error occurred."
                            }
                        }
                    }
                default:
                    self.errorMessage = "An unknown error occurred."
                }
            }
        }
    }
}
