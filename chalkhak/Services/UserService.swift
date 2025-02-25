//
//  UserService.swift
//  chalkhak
//
//  Created by 강구현 on 1/27/25.
//

import Foundation

class UserService {
    static let shared = UserService()
    private init() {}
    
    private let baseURL = AppConfig.serverURL
    
    func fetchUser(
        userId: Int,
        completion: @escaping (Result<UserModel, UserServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
                    let user = try JSONDecoder().decode(UserModel.self, from: data)
                    completion(.success(user))
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
    
    func updateUser(
        userId: Int,
        email: String?,
        username: String?,
        phone: String?,
        fullname: String?,
        bio: String?,
        completion: @escaping (Result<Void, UserServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users/") else {
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
            "email": email ?? "",
            "username": username ?? "",
            "phone": phone ?? "",
            "fullname": fullname ?? "",
            "bio": bio ?? ""
        ]
        
        do {
            let jsonBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonBody
        } catch {
            return completion(.failure(.unknown))
        }
        
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
                    _ = try JSONDecoder().decode(PostModel.self, from: data)
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
    
    func followUser(
        userId: Int,
        followerId: Int,
        completion: @escaping (Result<Void, UserServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/follow") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        let body: [String: Any] = [
            "followerId": followerId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                return completion(.failure(.noData))
            }
            
            if (200..<300).contains(httpResponse.statusCode) {
                completion(.success(()))
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
    
    func unfollowUser(
        userId: Int,
        followerId: Int,
        completion: @escaping (Result<Void, UserServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/follow") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidToken))
        }
        
        let body: [String: Any] = [
            "followerId": followerId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                return completion(.failure(.noData))
            }
            
            if (200..<300).contains(httpResponse.statusCode) {
                completion(.success(()))
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
    
    func getFollowers(
        userId: Int,
        completion: @escaping (Result<[UserModel], UserServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/followers") else {
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
                    let users = try JSONDecoder().decode([UserModel].self, from: data)
                    completion(.success(users))
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
    
    func getFollowingUsers(
        userId: Int,
        completion: @escaping (Result<[UserModel], UserServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/followings") else {
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
                    let users = try JSONDecoder().decode([UserModel].self, from: data)
                    completion(.success(users))
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
}

enum UserServiceError: Error, Equatable {
    case invalidURL
    case invalidToken
    case noData
    case serverError(String)
    case unknown
}
