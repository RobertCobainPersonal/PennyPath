//
//  SimpleBalanceChart.swift
//  PennyPath
//
//  Created by Robert Cobain on 18/06/2025.
//


import SwiftUI
import Charts

/// Minimal working balance chart for testing
struct SimpleBalanceChart: View {
    let account: Account
    
    private var sampleData: [BalancePoint] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            BalancePoint(date: calendar.date(byAdding: .day, value: -7, to: today)!, balance: account.balance - 200),
            BalancePoint(date: calendar.date(byAdding: .day, value: -5, to: today)!, balance: account.balance - 100),
            BalancePoint(date: calendar.date(byAdding: .day, value: -3, to: today)!, balance: account.balance + 50),
            BalancePoint(date: today, balance: account.balance),
            BalancePoint(date: calendar.date(byAdding: .day, value: 3, to: today)!, balance: account.balance + 100),
            BalancePoint(date: calendar.date(byAdding: .day, value: 7, to: today)!, balance: account.balance + 250)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Forecast")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(sampleData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let balance = value.as(Double.self) {
                            Text(balance.formattedAsCurrencyCompact)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct BalancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

// MARK: - Preview
struct SimpleBalanceChart_Previews: PreviewProvider {
    static var previews: some View {
        SimpleBalanceChart(
            account: Account(userId: "test", name: "Test Account", type: .current, balance: 2500.0)
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}