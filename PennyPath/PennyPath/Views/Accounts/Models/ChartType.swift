//
//  ChartType.swift
//  PennyPath
//
//  Created by Robert Cobain on 20/06/2025.
//


import Foundation

/// Represents the different types of charts available in account detail views
/// Used for chart selection and routing to appropriate chart components
enum ChartType: String, CaseIterable, Identifiable {
    case balanceForecast = "balance"
    case spendingTrends = "spending"
    case paymentSchedule = "schedule"
    
    var id: String { rawValue }
    
    /// Full descriptive name for the chart type
    var displayName: String {
        switch self {
        case .balanceForecast: return "Balance Forecast"
        case .spendingTrends: return "Spending Trends"
        case .paymentSchedule: return "Payment Schedule"
        }
    }
    
    /// Short name for tab labels and compact displays
    var shortName: String {
        switch self {
        case .balanceForecast: return "Balance"
        case .spendingTrends: return "Trends"
        case .paymentSchedule: return "Schedule"
        }
    }
    
    /// System icon representing the chart type
    var icon: String {
        switch self {
        case .balanceForecast: return "chart.line.uptrend.xyaxis"
        case .spendingTrends: return "chart.pie"
        case .paymentSchedule: return "calendar.badge.clock"
        }
    }
    
    /// Brief description of what the chart shows
    var description: String {
        switch self {
        case .balanceForecast: return "30-day balance projection with scheduled payments"
        case .spendingTrends: return "Category breakdown and merchant analysis"
        case .paymentSchedule: return "Upcoming payments calendar view"
        }
    }
    
    /// Whether this chart type requires scheduled transactions
    var requiresScheduledTransactions: Bool {
        switch self {
        case .balanceForecast, .paymentSchedule: return true
        case .spendingTrends: return false
        }
    }
    
    /// Whether this chart type requires transaction history
    var requiresTransactionHistory: Bool {
        switch self {
        case .spendingTrends, .balanceForecast: return true
        case .paymentSchedule: return false
        }
    }
    
    /// Minimum number of data points needed for meaningful display
    var minimumDataPoints: Int {
        switch self {
        case .balanceForecast: return 1 // Just need current balance
        case .spendingTrends: return 3 // Need some transactions to categorize
        case .paymentSchedule: return 1 // Just need one scheduled payment
        }
    }
}

// MARK: - Chart Type Extensions

extension ChartType {
    /// Returns appropriate chart types for a given account type
    static func availableTypes(for accountType: AccountType) -> [ChartType] {
        switch accountType {
        case .current, .savings:
            return [.balanceForecast, .spendingTrends, .paymentSchedule]
        case .credit:
            return [.balanceForecast, .spendingTrends, .paymentSchedule]
        case .loan:
            return [.balanceForecast, .paymentSchedule] // Loans don't have varied spending
        case .bnpl:
            return [.paymentSchedule] // BNPL focused on payment schedules
        @unknown default:
            return [.balanceForecast, .spendingTrends, .paymentSchedule] // Safe fallback with all options
        }
    }
    
    /// Default chart type for a given account type
    static func defaultType(for accountType: AccountType) -> ChartType {
        switch accountType {
        case .current, .savings:
            return .balanceForecast
        case .credit:
            return .spendingTrends // Credit cards focus on spending analysis
        case .loan, .bnpl:
            return .paymentSchedule // Loan/BNPL focus on payment schedules
        @unknown default:
            return .balanceForecast // Safe fallback to most universal chart type
        }
    }
}
