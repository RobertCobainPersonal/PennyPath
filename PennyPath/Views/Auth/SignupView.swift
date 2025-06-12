//
//  SignupView.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @Environment(\.dismiss) var dismiss // To go back to the login screen
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // MARK: - Header
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Join PennyPath and start your journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Form Fields
            VStack(spacing: 16) {
                TextField("Full Name", text: $fullName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // MARK: - Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // MARK: - Sign Up Button
            Button(action: {
                Task {
                    await viewModel.signUp(withEmail: email, password: password, fullName: fullName)
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign Up")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty || fullName.isEmpty)
            .padding(.horizontal)

            Spacer()
            
            // MARK: - Back to Login
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                    Text("Log In")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
        }
        .padding()
        // Clear any previous error messages when this view appears
        .onAppear {
            viewModel.errorMessage = nil
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
