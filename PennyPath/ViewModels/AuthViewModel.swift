//
//  AuthViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
// We no longer need Combine for this part, but it's fine to leave the import
import Combine

@MainActor
class AuthViewModel: ObservableObject {

    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // The handle for the auth state listener
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // We now call a method to set up the traditional listener
        listenToAuthState()
    }
    
    // This method replaces the Combine-based setup
    func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            self.userSession = user
            
            if let user = user {
                // User is signed in, fetch their profile
                self.fetchUser(userId: user.uid)
            } else {
                // User is signed out
                self.currentUser = nil
            }
        }
    }

    // MARK: - Public API

    func signIn(withEmail email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            print("DEBUG: User signed in successfully.")
        } catch {
            print("DEBUG: Failed to sign in with error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(withEmail email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("DEBUG: User signed up successfully.")
            await storeUserInFirestore(userId: result.user.uid, email: email, fullName: fullName)
        } catch {
            print("DEBUG: Failed to sign up with error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            print("DEBUG: User signed out.")
        } catch {
            print("DEBUG: Failed to sign out with error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private Helpers

    private func storeUserInFirestore(userId: String, email: String, fullName: String) async {
        let userData = ["id": userId, "email": email, "fullName": fullName]
        let db = Firestore.firestore()
        
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("DEBUG: Stored user profile in Firestore.")
        } catch {
            print("DEBUG: Failed to store user in Firestore: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }

    private func fetchUser(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "Could not retrieve user data."
                return
            }
            self.currentUser = User(id: data["id"] as? String ?? "",
                                    fullName: data["fullName"] as? String ?? "",
                                    email: data["email"] as? String ?? "")
            print("DEBUG: Fetched user: \(self.currentUser?.fullName ?? "N/A")")
        }
    }
    
    // Clean up the listener when the ViewModel is deallocated
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
