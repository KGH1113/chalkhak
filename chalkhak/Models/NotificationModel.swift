//
//  NotificationModel.swift
//  chalkhak
//
//  Created by 강구현 on 1/31/25.
//

import Foundation

struct NotificationModel: Codable {
    let id: Int
    let type: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let updatedAt: String
    let fromUserId: Int
    let recipientId: Int
    let postId: Int?
    let commentId: Int?
}
