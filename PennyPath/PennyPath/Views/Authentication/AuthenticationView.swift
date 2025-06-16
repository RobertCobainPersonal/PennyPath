//
//  AuthenticationView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appStore: AppStore
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("PennyPath")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if isSignUp {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: authenticate) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.caption)
            }
            
            // Test Rules Button
            Button("Test Security Rules") {
                Task {
                    await appStore.testFirestoreRules()
                }
            }
            .padding(.top, 20)
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
    }
    
    private func authenticate() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isSignUp {
                    try await appStore.signUp(email: email, password: password, firstName: firstName)
                } else {
                    try await appStore.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}