//
//  UploadService.swift
//  chalkhak
//
//  Created by 강구현 on 1/22/25.
//

import Foundation
import UIKit

class UploadService {
    static let shared = UploadService()
    private init() {}
    
    private let baseURL = AppConfig.serverURL
    
    func uploadImage(
        image: UIImage,
        completion: @escaping (Result<String, UploadError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/upload") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return completion(.failure(.invalidImageData))
        }
        
        let formFieldName = "image"
        var body = Data()
        
        // boundary
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        // Content-Disposition
        body.append("Content-Disposition: form-data; name=\"\(formFieldName)\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        // Content-Type
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        // Actual file bytes
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                return completion(.failure(.noData))
            }
            
            if (200..<300).contains(httpResponse.statusCode) {
                do {
                    let result = try JSONDecoder().decode(ImageUploadResponse.self, from: data)
                    completion(.success(result.imageUrl))
                } catch {
                    completion(.failure(.noData))
                }
            } else if httpResponse.statusCode == 401 {
                completion(.failure(.invalidToken))
            } else {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.message)))
                } catch {
                    completion(.failure(.unknown))
                }
            }
        }.resume()
    }
}

enum UploadError: Error, Equatable {
    case invalidURL
    case invalidImageData
    case invalidToken
    case noData
    case decodeError
    case serverError(String)
    case unknown
}

struct ImageUploadResponse: Codable {
    let imageUrl: String
}
