//
//  PostService.swift
//  chalkhak
//
//  Created by 강구현 on 1/22/25.
//

import Foundation

class PostService {
    static let shared = PostService()
    private init() {}
    
    private let baseURL = AppConfig.serverURL
    
    func createPost(
        title: String,
        content: String,
        latitude: Double,
        longitude: Double,
        imageUrl: String?,
        completion: @escaping (Result<Void, PostError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/posts") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        let body: [String: Any] = [
            "title": title,
            "content": content,
            "latitude": latitude,
            "longitude": longitude,
            "imageUrl": imageUrl ?? ""
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Convert body dictionary to JSON data
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                return completion(.failure(.noData))
            }
            
            // Check the status code range
            if (200..<300).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else if httpResponse.statusCode == 401 {
                completion(.failure(.invalidToken))
            } else {
                // Parsse the error from the JSON
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.message)))
                } catch {
                    completion(.failure(.unknown))
                }
            }
        }.resume()
    }
    
    func fetchAllPost(completion: @escaping (Result<[PostModel], PostError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
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
                    let posts = try JSONDecoder().decode([PostModel].self, from: data)
                    completion(.success(posts))
                } catch {
                    completion(.failure(.unknown))
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
    
    func fetchPost(byId id: Int, completion: @escaping (Result<PostModel, PostError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/posts\(id)") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
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
                    let post = try JSONDecoder().decode(PostModel.self, from: data)
                    completion(.success(post))
                } catch {
                    completion(.failure(.unknown))
                }
            } else if httpResponse.statusCode == 401 {
                completion(.failure(.invalidToken))
            } else if httpResponse.statusCode == 404 {
                completion(.failure(.serverError("Post not found")))
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
    
    func updatePost(
        id: Int,
        title: String,
        content: String?,
        imageUrl: String?,
        completion: @escaping (Result<Void, PostError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/posts/\(id)") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "title": title,
            "content": content ?? "",
            "imageUrl": imageUrl ?? ""
        ]
        
        do {
            let jsonBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonBody
        } catch {
            return completion(.failure(.unknown))
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                return completion(.failure(.noData))
            }
            
            if (200..<300).contains(httpResponse.statusCode) {
                do {
                    _ = try JSONDecoder().decode(PostModel.self, from: data)
                    completion(.success(()))
                } catch {
                    completion(.failure(.unknown))
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
    
    func deletePost(
        id: Int,
        completion: @escaping (Result<Void, PostError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/posts/\(id)") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return completion(.failure(.noData))
            }
            
            if (200..<300).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else if httpResponse.statusCode == 401 {
                completion(.failure(.invalidToken))
            } else {
                if let data = data {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        completion(.failure(.serverError(errorResponse.message)))
                    } catch {
                        completion(.failure(.unknown))
                    }
                } else {
                    completion(.failure(.noData))
                }
            }
        }.resume()
    }
}

enum PostError: Error, Equatable {
    case serverError(String)
    case invalidToken
    case invalidURL
    case noData
    case unknown
}
