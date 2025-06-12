//
//  BNPLSchedulePreview.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import Foundation

/// A simple struct to hold the calculated results of a BNPL plan for UI preview.
/// This is passed from the View layer to the Service layer when creating a BNPL transaction.
struct BNPLSchedulePreview {
    let initialPayment: Double
    let fee: Double
    let installmentAmount: Double
    let remainingBalance: Double
    let schedule: [(date: Date, amount: Double)]
}
