//
//  KeychainTestView.swift
//  chalkhak
//
//  Created by 강구현 on 1/17/25.
//

import SwiftUI

struct KeychainTestView: View {
    var body: some View {
        VStack {
            Button(action: {
                print(KeychainService.shared.retrive(key: "ACCESS_TOKEN") ?? "Error access")
                print(KeychainService.shared.retrive(key: "REFRESH_TOKEN") ?? "Error refresh")
                AuthService.shared.refreshToken() { Result in
                    print(Result)
                }
            }) {
                Text("Get Refresh Token and Access Token")
            }
            
            Button(action: {
                KeychainService.shared.delete(key: "ACCESS_TOKEN")
                KeychainService.shared.delete(key: "REFRESH_TOKEN")
            }) {
                Text("Delete Refresh Token and Access Token")
            }
        }
    }
}

#Preview {
    KeychainTestView()
}
