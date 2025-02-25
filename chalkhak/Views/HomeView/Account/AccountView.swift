//
//  AccountView.swift
//  chalkhak
//
//  Created by 강구현 on 1/18/25.
//

import SwiftUI
import MapKit

struct AccountView: View {
    @State private var isDrawerOpen: Bool = false
    
    @State private var username: String = ""
    @State private var fullname: String? = ""
    @State private var profilePicUrl: String? = ""
    @State private var bio: String? = ""
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var posts: [PostModel] = []
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        AuthService.shared.logout() { result in
                            switch result {
                            case .success:
                                authManager.isAuthenticated = false
                            case.failure(let error):
                                print(error)
                            }
                        }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .foregroundStyle(.red)
                }
                .padding()
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                HStack {
                    VStack {
                        VStack {
                            if let profilePicUrl {
                                Text(profilePicUrl)
                            } else {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .foregroundStyle(Color(UIColor.gray))
                            }
                        }
                        .padding(17)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .fill(Color.clear)
                                .stroke(.primary, lineWidth: 2)
                        }
                        Text(fullname ?? "@\(username)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("Followers")
                                .font(.system(size: 14, weight: .medium))
                            Text("\(followersCount)")
                                .font(.caption)
                        }
                        .onTapGesture {
                            print("Followers")
                        }
                        VStack {
                            Text("Following")
                                .font(.system(size: 14, weight: .medium))
                            Text("\(followingCount)")
                                .font(.caption)
                        }
                        .onTapGesture {
                            print("Following")
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                VStack {
                    Map {
                        ForEach(posts) { post in
                            Annotation(
                                "Post",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: post.latitude,
                                    longitude: post.longitude
                                )
                            ) {
                                Image(systemName: "location.circle")
                            }
                            .annotationTitles(.hidden)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .padding(.bottom, 70)
            .onAppear() {
                fetchUserData()
            }
        }
        BottomDrawer(isOpen: $isDrawerOpen, drawerHeight: 400) {
            VStack {
                Button(action: {
                    
                }) {
                    
                }
                
                Button(action: {
                    
                }) {
                    
                }
            }
        }
    }
    
    func fetchUserData() {
        let userId = UserDefaults.standard.integer(forKey: "userId")
        UserService.shared.fetchUser(userId: userId) { result in
            switch result {
            case .success(let user):
                username = user.username
                fullname = user.fullname
                profilePicUrl = user.profilePicUrl
                bio = user.bio
                if let followersCnt = user.followers?.count {
                    followersCount = followersCnt
                }
                if let followingCnt = user.followings?.count {
                    followingCount = followingCnt
                }
                if let uploadedPosts = user.posts {
                    posts = uploadedPosts
                }
            case .failure(let error):
//                switch error {
//                case .invalidToken:
//                    AuthService.shared.refreshToken { refreshResult in
//                        switch refreshResult {
//                        case .success():
//                            fetchUserData()
//                        case .failure(let refreshError):
//                            if refreshError == AuthError.invalidRefreshToken {
//                                authManager.isAuthenticated = false
//                            }
//                        }
//                    }
//                default:
//                    print("Error fetching user: \(error)")
//                }
            }
        }
    }
}
