//
//  CommentModel.swift
//  chalkhak
//
//  Created by 강구현 on 1/30/25.
//

import Foundation

struct CommentModel: Codable {
    let id: Int
    let content: String
    let createdAt: String
    let updatedAt: String
    let postId: Int
    let authorId: Int
}
