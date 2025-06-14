//
//  BNPLPlanListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


//
//  BNPLPlanListViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class BNPLPlanListViewModel: ObservableObject {
    
    @Published var plans = [BNPLPlan]()
    private var listenerRegistration: ListenerRegistration?
    
    func fetchPlans() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let collectionPath = "users/\(userId)/bnpl_plans"
        
        listenerRegistration?.remove() // Avoid duplicate listeners
        
        self.listenerRegistration = Firestore.firestore().collection(collectionPath)
            .order(by: "provider")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching BNPL plans: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.plans = documents.compactMap { try? $0.data(as: BNPLPlan.self) }
            }
    }
    
    deinit {
        print("BNPLPlanListViewModel deinitialized, removing listener.")
        listenerRegistration?.remove()
    }
}