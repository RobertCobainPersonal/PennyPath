//
//  TransactionType.swift
//  PennyPath
//
//  Created by Robert Cobain on 11/06/2025.
//


enum TransactionType: String, CaseIterable, Codable {
    case expense = "Expense"
    case income = "Income"
    case transfer = "Transfer"
}