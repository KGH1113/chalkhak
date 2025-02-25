//
//  FormView.swift
//  chalkhak
//
//  Created by 강구현 on 1/23/25.
//

import SwiftUI
import MapKit

struct FormView: View {
    let selectedImage: UIImage
    @Binding var title: String
    @Binding var content: String
    
    @Binding var errorMessage: String
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    isTitleFocused = false
                    isContentFocused = false
                }
            VStack {
                VStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
                .frame(width: 300, height: 300, alignment: .center)
                .clipped()
                .contentShape(Rectangle())
                .padding(.bottom, 15)
                
                VStack {
                    TextField(isTitleFocused ? "" : "Title", text: $title)
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .frame(height: 35)
                        .cornerRadius(8)
                        .overlay {
                            // Show a border only when focused
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.systemGray), lineWidth: isTitleFocused ? 1 : 0)
                        }
                        .focused($isTitleFocused)
                    
                    Divider()

                    TextEditor(text: $content)
                        .font(.system(size: 13))
                        .overlay(alignment: .topLeading) {
                            Text("Content")
                                .font(.system(size: 13))
                                .foregroundStyle(isContentFocused || !content.isEmpty ? .clear : Color(UIColor.systemGray3))
                                .padding(.top, 2)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .frame(height: 60)
                        .cornerRadius(8)
                        .overlay {
                            // Show a border only when focused
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor.systemGray), lineWidth: isContentFocused ? 1 : 0)
                        }
                        .focused($isContentFocused)
                }
                .padding()
                
                Spacer()
                
                VStack {
                    Map {
                        if let userLocation = locationManager.currentLocation {
                            Annotation("user location", coordinate: userLocation) {
                                Image(systemName: "person.fill")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .cornerRadius(10)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 40)
                        .font(.system(size: 12))
                }
            }
            .padding()
            .padding(.bottom, 70)
//            Spacer()
        }
    }
}
