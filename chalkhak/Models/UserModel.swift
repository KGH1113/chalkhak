//
//  UserModel.swift
//  chalkhak
//
//  Created by 강구현 on 1/13/25.
//

import Foundation

struct UserModel: Codable {
    let id: Int
    let email: String
    let username: String
    let phone: String
    let createdAt: String
    let updatedAt: String
    let fullname: String?
    let bio: String?
    let profilePicUrl: String?
    let password: String
    let comments: [CommentModel]?
    let likes: [LikeModel]?
    let followers: [UserModel]?
    let followings: [UserModel]?
    let posts: [PostModel]?
}
