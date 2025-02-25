//
//  AuthManager.swift
//  chalkhak
//
//  Created by 강구현 on 2/20/25.
//

import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
}
