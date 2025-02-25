//
//  AuthService.swift
//  chalkhak
//
//  Created by 강구현 on 1/13/25.
//

import Foundation
import Combine

class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private let baseURL = AppConfig.serverURL
    
    func login(
        email: String,
        password: String,
        completion: @escaping (Result<LoginResponse, AuthError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            return completion(.failure(AuthError.invalidURL))
        }
        
        let body: [String: Any] = ["email": email, "password": password]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                // Attempt to decode as success
                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    
                    let accessToken = loginResponse.accessToken
                    
                    // Parse the refresh token from the `Set-Cookie` header
                    guard let allHeaders = httpResponse.allHeaderFields as? [String: String],
                          let setCookieHeader = allHeaders["Set-Cookie"] else {
                        return completion(.failure(.noData))
                    }
                    let parsedRefreshToken = self.extractCookieValue(from: setCookieHeader, cookieName: "refreshToken")
                    
                    KeychainService.shared.save(token: accessToken, key: "ACCESS_TOKEN")
                    if let actualRefreshToken = parsedRefreshToken {
                        KeychainService.shared.save(token: actualRefreshToken, key: "REFRESH_TOKEN")
                    }
                    completion(.success(loginResponse))
                } catch {
                    // If failed decoding, treat as unknown error
                    completion(.failure(.unknown))
                }
            } else {
                // Parse the error from the JSON
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.message)))
                } catch {
                    completion(.failure(.unknown))
                }
            }
        }.resume()
    }
    
    // MARK: - Refresh Token
    func refreshToken(completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let refreshToken = KeychainService.shared.retrive(key: "REFRESH_TOKEN") else {
            return completion(.failure(.invalidRefreshToken))
        }
        
        let body: [String: Any] = ["refreshToken": refreshToken]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                // Attempt to decode as a success
                do {
                    let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                    
                    let newAccessToken = authResponse.accessToken
                    
                    // Parse the refresh token from the `Set-Cookie` header
                    guard let allHeaders = httpResponse.allHeaderFields as? [String: String],
                          let setCookieHeader = allHeaders["Set-Cookie"] else {
                        return completion(.failure(.noData))
                    }
                    let parsedRefreshToken = self.extractCookieValue(from: setCookieHeader, cookieName: "refreshToken")
                    
                    KeychainService.shared.save(token: newAccessToken, key: "ACCESS_TOKEN")
                    if let actualRefreshToken = parsedRefreshToken {
                        KeychainService.shared.save(token: actualRefreshToken, key: "REFRESH_TOKEN")
                    }
                    completion(.success(()))
                } catch {
                    // If failed decoding, treat as unknown error
                    completion(.failure(.unknown))
                }
            } else if httpResponse.statusCode == 201 {
                completion(.failure(.invalidRefreshToken))
            } else {
                // Parse the error from the JSON
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.message)))
                } catch {
                    completion(.failure(.unknown))
                }
            }
        }.resume()
    }
    
    func register(
        userData: [String: Any],
        completion: @escaping (Result<RegisterResponse, AuthError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/users") else {
            return completion(.failure(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert the dictionary to JSON data
        request.httpBody = try? JSONSerialization.data(withJSONObject: userData, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(.serverError(error.localizedDescription)))
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                return completion(.failure(.noData))
            }
            
            // Check the status code range
            if (200..<300).contains(httpResponse.statusCode) {
                // Attempt to decode as a success
               do {
                   let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                   completion(.success(registerResponse))
               } catch {
                   // If failed decoding, treat as unknown error
                   print(data)
                   return completion(.failure(.unknown))
               }
           } else {
               // Parse error from JSON
               do {
                   let jsonError = try JSONDecoder().decode([String: String].self, from: data)
                   let errorMessage = jsonError["message"] ?? "Server Error"
                   completion(.failure(.serverError(errorMessage)))
               } catch {
                   completion(.failure(.unknown))
               }
           }
        }.resume()
    }
    
    func protectedRoute(completion: @escaping (Result<protectedResponse, AuthError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/protected") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let token = KeychainService.shared.retrive(key: "ACCESS_TOKEN") else {
            return completion(.failure(.invalidAccessToken))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
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
                    let response = try JSONDecoder().decode(protectedResponse.self, from: data)
                    UserDefaults.standard.set(response.userId, forKey: "userId")
                    completion(.success(response))
                } catch {
                    print("here1")
                    completion(.failure(.unknown))
                }
            } else if httpResponse.statusCode == 401 {
                completion(.failure(.invalidAccessToken))
            } else {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    completion(.failure(.serverError(errorResponse.message)))
                } catch {
                    print("here2")
                    completion(.failure(.unknown))
                }
            }
        }.resume()
    }
    
    func logout(completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/logout") else {
            return completion(.failure(.invalidURL))
        }
        
        guard let refreshToken = KeychainService.shared.retrive(key: "REFRESH_TOKEN") else {
            return completion(.failure(.invalidRefreshToken))
        }
        
        let body: [String: Any] = ["refreshToken": refreshToken]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
            
            if (200..<300).contains(httpResponse.statusCode) {
                do {
                    let _ = try JSONDecoder().decode(logoutResponse.self, from: data)
                    UserDefaults.standard.removeObject(forKey: "userId")
                    KeychainService.shared.delete(key: "ACCESS_TOKEN")
                    KeychainService.shared.delete(key: "REFRESH_TOKEN")
                    completion(.success(()))
                } catch {
                    completion(.failure(.unknown))
                }
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
    
    private func extractCookieValue(from cookieString: String, cookieName: String) -> String? {
        guard let nameRange = cookieString.range(of: "\(cookieName)=") else {
            return nil
        }
        
        // Slice from the end of `cookieName=` onward
        let afterName = cookieString[nameRange.upperBound...]
        
        // Find where that cookie's value
        if let semicolonIndex = afterName.firstIndex(of: ";") {
            // Everything between `cookieName=` and `;`
            return String(afterName[..<semicolonIndex])
        } else{
            // If there's no semicolon, maybe cookie is the last in the header
            return String(afterName)
        }
    }
}

enum AuthError: Error, Equatable {
    case serverError(String)
    case invalidURL
    case noData
    case invalidRefreshToken
    case invalidAccessToken
    case unknown
}

struct LoginResponse: Codable {
    let accessToken: String
}

struct AuthResponse: Codable {
    let accessToken: String
}

struct RegisterResponse: Codable {
    let id: Int
    let email: String
    let username: String
    let phone: String
    let createdAt: String
    let updatedAt: String
    let fullname: String?
    let bio: String?
    let password: String
    let profilePicUrl: String?
}

struct protectedResponse: Codable {
    let userId: Int
}

struct logoutResponse: Codable {
    let message: String
}
