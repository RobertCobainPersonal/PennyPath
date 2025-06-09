//
//  Account.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//
// Models/Account.swift
import Foundation
import FirebaseFirestore
import SwiftUI // Added for Color

// MARK: - Main Account Struct
/**
 * This is the primary data model for a financial account.
 * It has been updated to support historical balance tracking by including
 * an `openingBalanceDate` alongside an `openingBalance`.
 */
struct Account: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var institution: String
    var currency: String = "GBP"
    
    // This is the core of our flexible model. It holds the details specific to the account type.
    var details: AccountDetails
    
    // For now, currentBalance reflects the most recent known balance.
    // This will be replaced later by a calculation.
    var currentBalance: Double {
        switch details {
        case .currentAccount(let data): return data.openingBalance
        case .savingsAccount(let data): return data.openingBalance
        case .creditCard(let data): return data.openingBalance
        case .loan(let data): return data.outstandingBalance
        case .bnpl(let data): return data.outstandingBalance
        case .generic(let data): return data.openingBalance
        case .familyLoan(let data): return data.outstandingBalance
        case .collectionAccount(let data): return data.outstandingBalance
        }
    }
    
    // Last updated timestamp for synchronization purposes.
    var lastUpdated: Timestamp = Timestamp(date: Date())
    
    // **NEW**: UI Helper property to provide an icon based on the account type.
    var icon: (name: String, color: Color) {
        switch details {
        case .currentAccount: return ("sterlingsign.circle.fill", .blue)
        case .savingsAccount: return ("banknote.fill", .green)
        case .creditCard: return ("creditcard.fill", .purple)
        case .loan: return ("doc.text.fill", .orange)
        case .bnpl: return ("tag.fill", .cyan)
        case .familyLoan: return ("person.2.fill", .pink)
        case .collectionAccount: return ("exclamationmark.triangle.fill", .red)
        case .generic: return ("questionmark.circle.fill", .gray)
        }
    }
}


// MARK: - Account Details Enum & Structs
// ... No changes to the rest of the file ...
enum AccountDetails: Codable {
    case currentAccount(CurrentAccountDetails)
    case savingsAccount(SavingsAccountDetails)
    case creditCard(CreditCardDetails)
    case loan(LoanDetails)
    case bnpl(BNPLDetails)
    case generic(GenericDetails)
    case familyLoan(FamilyLoanDetails)
    case collectionAccount(CollectionAccountDetails)

    // Codable implementation remains the same.
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .currentAccount(let d): try container.encode("currentAccount", forKey: .type); try container.encode(d, forKey: .data)
        case .savingsAccount(let d): try container.encode("savingsAccount", forKey: .type); try container.encode(d, forKey: .data)
        case .creditCard(let d): try container.encode("creditCard", forKey: .type); try container.encode(d, forKey: .data)
        case .loan(let d): try container.encode("loan", forKey: .type); try container.encode(d, forKey: .data)
        case .bnpl(let d): try container.encode("bnpl", forKey: .type); try container.encode(d, forKey: .data)
        case .generic(let d): try container.encode("generic", forKey: .type); try container.encode(d, forKey: .data)
        case .familyLoan(let d): try container.encode("familyLoan", forKey: .type); try container.encode(d, forKey: .data)
        case .collectionAccount(let d): try container.encode("collectionAccount", forKey: .type); try container.encode(d, forKey: .data)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "currentAccount": self = .currentAccount(try container.decode(CurrentAccountDetails.self, forKey: .data))
        case "savingsAccount": self = .savingsAccount(try container.decode(SavingsAccountDetails.self, forKey: .data))
        case "creditCard": self = .creditCard(try container.decode(CreditCardDetails.self, forKey: .data))
        case "loan": self = .loan(try container.decode(LoanDetails.self, forKey: .data))
        case "bnpl": self = .bnpl(try container.decode(BNPLDetails.self, forKey: .data))
        case "generic": self = .generic(try container.decode(GenericDetails.self, forKey: .data))
        case "familyLoan": self = .familyLoan(try container.decode(FamilyLoanDetails.self, forKey: .data))
        case "collectionAccount": self = .collectionAccount(try container.decode(CollectionAccountDetails.self, forKey: .data))
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid account type")
        }
    }
}

/**
 * The individual structs that hold the specific data for each account type.
 * Loan-style accounts now include an origination date for better analytics.
 */

struct CurrentAccountDetails: Codable {
    var openingBalance: Double
    var openingBalanceDate: Timestamp
}

struct SavingsAccountDetails: Codable {
    var openingBalance: Double
    var openingBalanceDate: Timestamp
    var apy: Double?
}
 
struct GenericDetails: Codable {
    var openingBalance: Double
    var openingBalanceDate: Timestamp
}

struct CreditCardDetails: Codable {
    var openingBalance: Double
    var openingBalanceDate: Timestamp
    var creditLimit: Double
    var paymentDueDate: Timestamp?
    var apr: Double?
}

// UPDATED: Now includes originationDate
struct LoanDetails: Codable {
    var originationDate: Timestamp
    var originalAmount: Double
    var outstandingBalance: Double
    var interestRate: Double
    var termInMonths: Int
    var nextPaymentDate: Timestamp?
}

// UPDATED: Now includes originationDate
struct BNPLDetails: Codable {
    var originationDate: Timestamp
    var originalPurchaseAmount: Double
    var outstandingBalance: Double
    var provider: String
    var remainingInstallments: Int
    var nextPaymentDate: Timestamp?
}

// UPDATED: Now includes loanDate
struct FamilyLoanDetails: Codable {
    var loanDate: Timestamp
    var isLender: Bool
    var counterparty: String
    var originalAmount: Double
    var outstandingBalance: Double
    var interestRate: Double?
    var dueDate: Timestamp?
}

// UPDATED: Now includes dateAssigned
struct CollectionAccountDetails: Codable {
    var dateAssigned: Timestamp
    var agency: String
    var originalCreditor: String?
    var originalAccountNumber: String?
    var outstandingBalance: Double
    var settlementAmount: Double?
}


// MARK: - AccountType Enum for UI
// This remains unchanged as it only controls UI presentation.
enum AccountUIType: String, CaseIterable, Identifiable {
    case currentAccount = "Current Account"
    case savingsAccount = "Savings Account"
    case creditCard = "Credit Card"
    case loan = "Loan"
    case bnpl = "Buy Now, Pay Later"
    case familyLoan = "Family/Friend Loan"
    case collectionAccount = "Collection Account"
    case generic = "General Account"
    
    var id: String { self.rawValue }
}
