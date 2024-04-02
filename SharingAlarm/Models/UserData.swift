//
//  UserData.swift
//  SharingAlarm
//
//  Created by 曹越程 on 2024/4/1.
//

import Foundation
import CloudKit
import AuthenticationServices

struct AppUser {
    var id: String  // A unique identifier, e.g., Apple ID, Google ID
    var username: String
    var email: String
    var authMethod: AuthMethod
}

enum AuthMethod {
    case apple
    case google
    // Add more as needed
}

