//
//  ImagePickerView.swift
//  chalkhak
//
//  Created by 강구현 on 1/23/25.
//

import SwiftUI
import Photos

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage
    @StateObject private var viewModel = PhotoLibraryViewModel()
    
    @State private var selectedAsset: PHAsset?
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFit()
                .frame(height: 350)
            Divider()
            Group {
                switch viewModel.authorizationsStatus {
                case .notDetermined:
                    ProgressView()
                case .authorized, .limited:
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.assets, id: \.self) { asset in
                                PhotoThumbnailView(
                                    asset: asset,
                                    isSelected: asset == selectedAsset
                                ) { selectedThumb in
                                    pickAsset(asset)
                                    selectedAsset = selectedThumb
                                }
                            }
                        }
                        .padding(.bottom, 80)
                    }
                case .denied, .restricted:
                    Text("Photos permission denied. Pleas grant permission in Settings.")
                @unknown default:
                    Text("Unknown error")
                }
            }
        }
        .onAppear() {
            pickAsset(viewModel.assets.first ?? PHAsset())
            selectedAsset = viewModel.assets.first ?? PHAsset()
        }
    }
    
    private func pickAsset(_ asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        
        let targetSize = CGSize(width: 1600, height: 1600)
        
        PHCachingImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            guard let image = image else { return }
            selectedImage = image
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    var onTap: (PHAsset) -> Void
    
    @State private var thumbnail: UIImage?
    
    private let thumbnailSize = CGSize(width: 200, height: 200)
    private let imageManager = PHCachingImageManager()
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .opacity(isSelected ? 0.7 : 1)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
            }
            
            if isSelected {
                Color.black.opacity(0.3)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .padding(4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(asset)
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .fastFormat
        
        imageManager.requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            self.thumbnail = image
        }
    }
}
