//
//  QuickAmountButtons.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//

import SwiftUI

/// Reusable quick amount selection component
/// Used in AddTransaction, budget setup, and payment forms
struct QuickAmountButtons: View {
    @Binding var selectedAmount: String
    let amounts: [Double]
    let title: String
    let showTitle: Bool
    let buttonStyle: QuickAmountButtonStyle
    
    init(
        selectedAmount: Binding<String>,
        amounts: [Double] = [5.0, 10.0, 25.0, 50.0, 100.0],
        title: String = "Quick Amounts",
        showTitle: Bool = true,
        buttonStyle: QuickAmountButtonStyle = .rounded
    ) {
        self._selectedAmount = selectedAmount
        self.amounts = amounts
        self.title = title
        self.showTitle = showTitle
        self.buttonStyle = buttonStyle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showTitle {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(amounts, id: \.self) { amount in
                        quickAmountButton(for: amount)
                    }
                }
                .padding(.horizontal, 1) // Prevent clipping of shadows
            }
        }
    }
    
    private func quickAmountButton(for amount: Double) -> some View {
        Button(action: {
            selectedAmount = String(format: "%.2f", amount)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Text(formatAmountForButton(amount))
                .font(buttonStyle.font)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, buttonStyle.horizontalPadding)
                .padding(.vertical, buttonStyle.verticalPadding)
                .background(buttonStyle.backgroundColor)
                .cornerRadius(buttonStyle.cornerRadius)
        }
        .buttonStyle(.plain)
    }
    
    private func formatAmountForButton(_ amount: Double) -> String {
        if amount >= 1000 {
            return "£\(Int(amount / 1000))K"
        } else {
            return "£\(Int(amount))"
        }
    }
}

/// Styling options for quick amount buttons
enum QuickAmountButtonStyle {
    case rounded
    case pill
    case minimal
    case large
    
    var font: Font {
        switch self {
        case .rounded, .pill, .minimal:
            return .subheadline
        case .large:
            return .headline
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .rounded, .pill:
            return 16
        case .minimal:
            return 12
        case .large:
            return 20
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .rounded, .pill:
            return 8
        case .minimal:
            return 6
        case .large:
            return 12
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .rounded, .pill, .large:
            return Color.blue.opacity(0.1)
        case .minimal:
            return Color.clear
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .rounded:
            return 8
        case .pill:
            return 20
        case .minimal:
            return 4
        case .large:
            return 12
        }
    }
}

/// Predefined amount sets for different use cases
struct QuickAmountPresets {
    /// Common small amounts for daily expenses
    static let dailyExpenses: [Double] = [2.0, 5.0, 10.0, 15.0, 25.0]
    
    /// Standard amounts for general transactions
    static let standard: [Double] = [5.0, 10.0, 25.0, 50.0, 100.0]
    
    /// Larger amounts for bills and transfers
    static let bills: [Double] = [50.0, 100.0, 200.0, 500.0, 1000.0]
    
    /// Budget amounts for monthly planning
    static let budgets: [Double] = [100.0, 200.0, 300.0, 500.0, 1000.0]
    
    /// BNPL common amounts
    static let bnpl: [Double] = [25.0, 50.0, 100.0, 200.0, 500.0]
}

/// Specialized quick amount component for budget setup
struct BudgetQuickAmounts: View {
    @Binding var selectedAmount: String
    
    var body: some View {
        QuickAmountButtons(
            selectedAmount: $selectedAmount,
            amounts: QuickAmountPresets.budgets,
            title: "Common Budget Amounts",
            buttonStyle: .large
        )
    }
}

/// Specialized quick amount component for bill payments
struct BillQuickAmounts: View {
    @Binding var selectedAmount: String
    
    var body: some View {
        QuickAmountButtons(
            selectedAmount: $selectedAmount,
            amounts: QuickAmountPresets.bills,
            title: "Common Bill Amounts",
            buttonStyle: .pill
        )
    }
}

/// Minimal quick amounts for inline use
struct InlineQuickAmounts: View {
    @Binding var selectedAmount: String
    let amounts: [Double]
    
    init(selectedAmount: Binding<String>, amounts: [Double] = QuickAmountPresets.dailyExpenses) {
        self._selectedAmount = selectedAmount
        self.amounts = amounts
    }
    
    var body: some View {
        QuickAmountButtons(
            selectedAmount: $selectedAmount,
            amounts: amounts,
            showTitle: false,
            buttonStyle: .minimal
        )
    }
}

// MARK: - Preview Provider
struct QuickAmountButtons_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Standard style
                VStack(alignment: .leading, spacing: 16) {
                    Text("Standard Quick Amounts")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    QuickAmountButtons(
                        selectedAmount: .constant(""),
                        amounts: QuickAmountPresets.standard
                    )
                }
                
                Divider()
                
                // Different styles
                VStack(alignment: .leading, spacing: 16) {
                    Text("Different Button Styles")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        QuickAmountButtons(
                            selectedAmount: .constant(""),
                            amounts: [5, 10, 25],
                            title: "Rounded Style",
                            buttonStyle: .rounded
                        )
                        
                        QuickAmountButtons(
                            selectedAmount: .constant(""),
                            amounts: [5, 10, 25],
                            title: "Pill Style",
                            buttonStyle: .pill
                        )
                        
                        QuickAmountButtons(
                            selectedAmount: .constant(""),
                            amounts: [5, 10, 25],
                            title: "Minimal Style",
                            buttonStyle: .minimal
                        )
                        
                        QuickAmountButtons(
                            selectedAmount: .constant(""),
                            amounts: [5, 10, 25],
                            title: "Large Style",
                            buttonStyle: .large
                        )
                    }
                }
                
                Divider()
                
                // Preset variants
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preset Variants")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        BudgetQuickAmounts(selectedAmount: .constant(""))
                        
                        BillQuickAmounts(selectedAmount: .constant(""))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Expenses (Inline)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            InlineQuickAmounts(selectedAmount: .constant(""))
                        }
                    }
                }
                
                Divider()
                
                // Large amounts with K formatting
                VStack(alignment: .leading, spacing: 16) {
                    Text("Large Amounts")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    QuickAmountButtons(
                        selectedAmount: .constant(""),
                        amounts: [1000, 2000, 5000, 10000, 25000],
                        title: "Investment Amounts"
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
