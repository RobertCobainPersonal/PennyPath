//
//  AuthErrorMessage.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//


import SwiftUI

struct AuthErrorMessage: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundColor(.red)
            .font(.caption)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}