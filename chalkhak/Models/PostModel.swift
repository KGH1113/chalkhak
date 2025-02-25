//
//  PostModel.swift
//  chalkhak
//
//  Created by 강구현 on 1/22/25.
//

import Foundation

struct PostModel: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String?
    let imageUrl: String?
    let latitude: Double
    let longitude: Double
    let createdAt: String
    let updatedAt: String
    let comments: [CommentModel]?
    let likes: [LikeModel]?
    let authorId: Int
}
