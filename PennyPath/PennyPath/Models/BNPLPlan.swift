//
//  BNPLPlan.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation
import FirebaseFirestore

/// BNPL Plan model for managing Buy Now Pay Later terms and schedules
/// Completely user-defined - no predefined providers
struct BNPLPlan: Identifiable, Codable {
    let id: String
    let userId: String
    let accountId: String
    let providerName: String // User-defined provider name
    let totalAmount: Double
    let numberOfInstallments: Int
    let installmentAmount: Double
    let frequency: PaymentFrequency
    let startDate: Date
    let description: String
    let lateFee: Double
    let interestRate: Double // Annual percentage rate
    var isCompleted: Bool
    let createdAt: Date
    
    init(id: String = UUID().uuidString, userId: String, accountId: String,
         providerName: String, totalAmount: Double, numberOfInstallments: Int,
         frequency: PaymentFrequency = .biweekly, startDate: Date = Date(),
         description: String, lateFee: Double = 0.0, interestRate: Double = 0.0) {
        self.id = id
        self.userId = userId
        self.accountId = accountId
        self.providerName = providerName
        self.totalAmount = totalAmount
        self.numberOfInstallments = numberOfInstallments
        self.installmentAmount = totalAmount / Double(numberOfInstallments)
        self.frequency = frequency
        self.startDate = startDate
        self.description = description
        self.lateFee = lateFee
        self.interestRate = interestRate
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    // MARK: - Firestore Integration
    
    /// Create BNPLPlan from Firestore document
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let accountId = data["accountId"] as? String,
              let providerName = data["providerName"] as? String,
              let totalAmount = data["totalAmount"] as? Double,
              let numberOfInstallments = data["numberOfInstallments"] as? Int,
              let installmentAmount = data["installmentAmount"] as? Double,
              let frequencyRaw = data["frequency"] as? String,
              let frequency = PaymentFrequency(rawValue: frequencyRaw),
              let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
              let description = data["description"] as? String,
              let lateFee = data["lateFee"] as? Double,
              let interestRate = data["interestRate"] as? Double,
              let isCompleted = data["isCompleted"] as? Bool,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.accountId = accountId
        self.providerName = providerName
        self.totalAmount = totalAmount
        self.numberOfInstallments = numberOfInstallments
        self.installmentAmount = installmentAmount
        self.frequency = frequency
        self.startDate = startDate
        self.description = description
        self.lateFee = lateFee
        self.interestRate = interestRate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
    
    /// Convert BNPLPlan to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "userId": userId,
            "accountId": accountId,
            "providerName": providerName,
            "totalAmount": totalAmount,
            "numberOfInstallments": numberOfInstallments,
            "installmentAmount": installmentAmount,
            "frequency": frequency.rawValue,
            "startDate": Timestamp(date: startDate),
            "description": description,
            "lateFee": lateFee,
            "interestRate": interestRate,
            "isCompleted": isCompleted,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    // MARK: - Helper Methods
    
    /// Generate payment schedule for this BNPL plan
    func generatePaymentSchedule() -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        
        for i in 0..<numberOfInstallments {
            let paymentDate: Date
            
            switch frequency {
            case .weekly:
                paymentDate = calendar.date(byAdding: .weekOfYear, value: i, to: startDate) ?? startDate
            case .biweekly:
                paymentDate = calendar.date(byAdding: .weekOfYear, value: i * 2, to: startDate) ?? startDate
            case .monthly:
                paymentDate = calendar.date(byAdding: .month, value: i, to: startDate) ?? startDate
            case .daily, .yearly:
                // Not typical for BNPL, but handle gracefully
                paymentDate = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            }
            
            dates.append(paymentDate)
        }
        
        return dates
    }
    
    /// Calculate final payment date
    var finalPaymentDate: Date {
        let calendar = Calendar.current
        let paymentsToAdd = numberOfInstallments - 1
        
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: paymentsToAdd, to: startDate) ?? startDate
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: paymentsToAdd * 2, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: paymentsToAdd, to: startDate) ?? startDate
        case .daily, .yearly:
            return calendar.date(byAdding: .day, value: paymentsToAdd, to: startDate) ?? startDate
        }
    }
    
    /// Check if this plan is overdue (has missed payments)
    func hasOverduePayments(transactions: [Transaction]) -> Bool {
        let paidTransactions = transactions.filter {
            $0.amount == -installmentAmount && !$0.isScheduled
        }
        let expectedPaymentsByNow = generatePaymentSchedule().filter { $0 <= Date() }
        
        return paidTransactions.count < expectedPaymentsByNow.count
    }
}

/// Payment frequency for BNPL plans and other scheduled payments
enum PaymentFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Fortnightly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
