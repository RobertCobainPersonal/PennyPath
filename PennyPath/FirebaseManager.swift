//
//  FirebaseManager.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//


import Foundation
import FirebaseCore

class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {} // Private initializer for singleton

    func configure() {
        FirebaseApp.configure()
        print("Firebase configured successfully!")
    }
}