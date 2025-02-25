//
//  PhotoLibraryViewModel.swift
//  chalkhak
//
//  Created by 강구현 on 1/23/25.
//

import SwiftUI
import Photos

class PhotoLibraryViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var authorizationsStatus: PHAuthorizationStatus = .notDetermined
    
    private let imageManager = PHCachingImageManager()
    
    init() {
        checkPermisionAndFetchPhotos()
    }
    
    func checkPermisionAndFetchPhotos() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized || status == .limited {
            self.authorizationsStatus = status
            self.fetchPhotoAssets()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    self.authorizationsStatus = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        self.fetchPhotoAssets()
                    }
                }
            }
        }
    }
    
    func fetchPhotoAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var fetchedAssets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, _, _) in
            fetchedAssets.append(asset)
        }
        self.assets = fetchedAssets
    }
    
    func requestThumbnail(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
}
