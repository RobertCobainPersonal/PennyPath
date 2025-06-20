//
//  SectionHeaderView.swift
//  PennyPath
//
//  Created by Robert Cobain on 20/06/2025.
//


import SwiftUI

/// Standardized section header with icon and title
/// Used throughout the app for consistent section styling
struct SectionHeaderView: View {
    let title: String
    let icon: String
    let titleColor: Color
    let iconColor: Color
    
    // Convenience initializer with default colors
    init(
        title: String,
        icon: String,
        titleColor: Color = .primary,
        iconColor: Color = .blue
    ) {
        self.title = title
        self.icon = icon
        self.titleColor = titleColor
        self.iconColor = iconColor
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(titleColor)
        }
    }
}

// MARK: - Preview Provider
struct SectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard headers
            SectionHeaderView(title: "Account Insights", icon: "chart.line.uptrend.xyaxis")
            
            SectionHeaderView(title: "Recent Transactions", icon: "list.bullet")
            
            SectionHeaderView(title: "Credit Information", icon: "creditcard")
            
            SectionHeaderView(title: "BNPL Plans", icon: "calendar.badge.clock")
            
            // Custom colors
            SectionHeaderView(
                title: "Danger Zone",
                icon: "exclamationmark.triangle",
                titleColor: .red,
                iconColor: .red
            )
            
            SectionHeaderView(
                title: "Success Metrics",
                icon: "checkmark.circle",
                titleColor: .green,
                iconColor: .green
            )
        }
        .padding()
        .previewDisplayName("Section Headers")
    }
}