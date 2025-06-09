//
//  AuthTextField.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//


import SwiftUI

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
        .textFieldStyle(.roundedBorder)
    }
}