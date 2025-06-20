//
//  DetailRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 20/06/2025.
//


import SwiftUI

/// Standardized key-value row component
/// Used in account details, transaction details, settings, and profile views
struct DetailRowView: View {
    let label: String
    let value: String
    let labelColor: Color
    let valueColor: Color
    let valueWeight: Font.Weight
    let showDivider: Bool
    
    // Convenience initializer with sensible defaults
    init(
        label: String,
        value: String,
        labelColor: Color = .secondary,
        valueColor: Color = .primary,
        valueWeight: Font.Weight = .medium,
        showDivider: Bool = false
    ) {
        self.label = label
        self.value = value
        self.labelColor = labelColor
        self.valueColor = valueColor
        self.valueWeight = valueWeight
        self.showDivider = showDivider
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(labelColor)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(valueWeight)
                    .foregroundColor(valueColor)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 8)
            
            if showDivider {
                Divider()
            }
        }
    }
}

// MARK: - Specialized Detail Row Variants

/// Currency detail row with proper formatting and color coding
struct CurrencyDetailRowView: View {
    let label: String
    let amount: Double
    let isPositive: Bool?
    let showDivider: Bool
    
    init(
        label: String,
        amount: Double,
        isPositive: Bool? = nil,
        showDivider: Bool = false
    ) {
        self.label = label
        self.amount = amount
        self.isPositive = isPositive
        self.showDivider = showDivider
    }
    
    var body: some View {
        DetailRowView(
            label: label,
            value: amount.formattedAsCurrency,
            valueColor: valueColor,
            valueWeight: .semibold,
            showDivider: showDivider
        )
    }
    
    private var valueColor: Color {
        if let isPositive = isPositive {
            return isPositive ? .green : .red
        }
        return amount >= 0 ? .green : .red
    }
}

/// Percentage detail row with progress indication
struct PercentageDetailRowView: View {
    let label: String
    let percentage: Double
    let showProgress: Bool
    let progressColor: Color?
    let showDivider: Bool
    
    init(
        label: String,
        percentage: Double,
        showProgress: Bool = false,
        progressColor: Color? = nil,
        showDivider: Bool = false
    ) {
        self.label = label
        self.percentage = percentage
        self.showProgress = showProgress
        self.progressColor = progressColor
        self.showDivider = showDivider
    }
    
    var body: some View {
        VStack(spacing: showProgress ? 8 : 0) {
            DetailRowView(
                label: label,
                value: "\(Int(percentage * 100))%",
                valueColor: displayColor,
                valueWeight: .semibold,
                showDivider: false
            )
            
            if showProgress {
                ProgressView(value: percentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: displayColor))
            }
            
            if showDivider {
                Divider()
            }
        }
    }
    
    private var displayColor: Color {
        if let color = progressColor {
            return color
        }
        
        // Default color coding for percentages
        if percentage > 0.8 { return .red }
        if percentage > 0.5 { return .orange }
        return .green
    }
}

/// Status detail row with colored status indicators
struct StatusDetailRowView: View {
    let label: String
    let status: String
    let statusColor: Color
    let showDivider: Bool
    
    init(
        label: String,
        status: String,
        statusColor: Color = .blue,
        showDivider: Bool = false
    ) {
        self.label = label
        self.status = status
        self.statusColor = statusColor
        self.showDivider = showDivider
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(6)
            }
            .padding(.vertical, 8)
            
            if showDivider {
                Divider()
            }
        }
    }
}

// MARK: - Preview Provider
struct DetailRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Standard detail rows
            DetailRowView(label: "Account Type", value: "Current Account", showDivider: true)
            DetailRowView(label: "Sort Code", value: "20-00-00", showDivider: true)
            DetailRowView(label: "Account Number", value: "12345678", showDivider: true)
            
            // Currency rows
            CurrencyDetailRowView(label: "Current Balance", amount: 2485.67, showDivider: true)
            CurrencyDetailRowView(label: "Available Credit", amount: -847.23, showDivider: true)
            
            // Percentage rows
            PercentageDetailRowView(
                label: "Credit Utilization",
                percentage: 0.65,
                showProgress: true,
                showDivider: true
            )
            
            PercentageDetailRowView(
                label: "Loan Progress",
                percentage: 0.35,
                showProgress: true,
                progressColor: .blue,
                showDivider: true
            )
            
            // Status rows
            StatusDetailRowView(
                label: "Account Status",
                status: "Active",
                statusColor: .green,
                showDivider: true
            )
            
            StatusDetailRowView(
                label: "Payment Status",
                status: "Overdue",
                statusColor: .red
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Detail Rows")
    }
}