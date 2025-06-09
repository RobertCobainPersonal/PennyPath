//
//  User.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//


import Foundation

// A simple model for our user profile data from Firestore
struct User: Identifiable {
    let id: String
    let fullName: String
    let email: String
}