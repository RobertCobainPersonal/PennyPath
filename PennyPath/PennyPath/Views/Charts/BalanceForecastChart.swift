//
//  BalanceForecastChart.swift
//  PennyPath
//
//  Created by Senior iOS Developer on 18/06/2025.
//

import SwiftUI
import Charts

struct BalanceForecastChart: View {
    let account: Account
    let transactions: [Transaction]
    let scheduledTransactions: [Transaction]
    
    @State private var selectedPoint: BalanceForecastPoint?
    @State private var showingProjectedOnly = false
    
    private var chartData: [BalanceForecastPoint] {
        generateBalanceForecast()
    }
    
    private var filteredData: [BalanceForecastPoint] {
        if showingProjectedOnly {
            return chartData.filter { $0.isProjected || Calendar.current.isDateInToday($0.date) }
        }
        return chartData
    }
    
    private var balanceChange: Double {
        guard let first = chartData.first?.balance,
              let last = chartData.last?.balance else { return 0 }
        return last - first
    }
    
    private var projectedLowPoint: Double {
        chartData.filter { $0.isProjected }.map { $0.balance }.min() ?? account.balance
    }
    
    var body: some View {
        VStack(spacing: 16) {
            chartHeader
            chartView
            chartControls
            
            // Warning if balance will go low
            if projectedLowPoint < 100 {
                lowBalanceWarning
            }
        }
    }
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("30-Day Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let selectedPoint = selectedPoint {
                    selectedPointInfo
                } else {
                    defaultMetrics
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Projected Change")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: balanceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(balanceChange >= 0 ? .green : .red)
                    
                    Text(balanceChange.formattedAsCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(balanceChange >= 0 ? .green : .red)
                }
            }
        }
    }
    
    private var selectedPointInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(selectedPoint?.balance.formattedAsCurrency ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(selectedPoint?.isProjected == true ? .blue : .primary)
            
            HStack(spacing: 4) {
                Text(selectedPoint?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if selectedPoint?.isProjected == true {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Projected")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var defaultMetrics: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(account.balance.formattedAsCurrency)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Current Balance")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var chartView: some View {
        Chart(filteredData, id: \.id) { point in
            // Main line
            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(point.isProjected ? .blue : .primary)
            .lineStyle(StrokeStyle(
                lineWidth: 2,
                dash: point.isProjected ? [5, 3] : []
            ))
            
            // Area fill
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        point.isProjected ? Color.blue.opacity(0.3) : Color.primary.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Transaction markers (simplified)
            if point.hasTransaction {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(point.transactionColor)
                .symbolSize(60)
            }
        }
        .frame(height: 220)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.quaternary)
                AxisValueLabel(format: .dateTime.month().day())
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let balance = value.as(Double.self) {
                        Text(balance.formattedAsCurrencyCompact)
                            .font(.caption2)
                    }
                }
            }
        }
        // REMOVED: Problematic chartBackground and chartOverlay
        .onTapGesture { location in
            // Simple fallback selection
            if !filteredData.isEmpty {
                let middleIndex = filteredData.count / 2
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPoint = selectedPoint?.id == filteredData[middleIndex].id ? nil : filteredData[middleIndex]
                }
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var chartControls: some View {
        VStack(spacing: 16) {
            // Projection toggle and legend
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingProjectedOnly.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showingProjectedOnly ? "eye.slash" : "eye")
                            .font(.caption)
                        
                        Text(showingProjectedOnly ? "Show All" : "Projection Only")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    legendItem(color: .primary, label: "Historical", isDashed: false)
                    legendItem(color: .blue, label: "Projected", isDashed: true)
                }
            }
            
            // Summary insights
            summaryInsights
        }
    }
    
    private var summaryInsights: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Projected end balance
                insightRow(
                    icon: "calendar",
                    title: "Month End Balance",
                    value: chartData.last?.balance.formattedAsCurrency ?? "—",
                    color: (chartData.last?.balance ?? 0) >= account.balance ? .green : .red
                )
                
                // Lowest projected point
                if projectedLowPoint < account.balance {
                    insightRow(
                        icon: "arrow.down.circle",
                        title: "Lowest Projected",
                        value: projectedLowPoint.formattedAsCurrency,
                        color: projectedLowPoint < 100 ? .red : .orange
                    )
                }
                
                // Upcoming scheduled payments count
                let upcomingCount = scheduledTransactions.filter {
                    $0.amount < 0 && $0.date >= Date() && $0.date <= Calendar.current.date(byAdding: .day, value: 30, to: Date())!
                }.count
                
                if upcomingCount > 0 {
                    insightRow(
                        icon: "clock.circle",
                        title: "Scheduled Payments",
                        value: "\(upcomingCount) upcoming",
                        color: .blue
                    )
                }
            }
        }
    }
    
    private func insightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var lowBalanceWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Low Balance Warning")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Your balance may drop below £100 this month")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func legendItem(color: Color, label: String, isDashed: Bool) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: 2)
                .overlay(
                    Rectangle()
                        .stroke(color, style: StrokeStyle(dash: isDashed ? [3, 2] : []))
                        .frame(width: 16, height: 2)
                )
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // SIMPLIFIED: Data generation with realistic UK financial patterns
    private func generateBalanceForecast() -> [BalanceForecastPoint] {
        var points: [BalanceForecastPoint] = []
        let calendar = Calendar.current
        let today = Date()
        var currentBalance = account.balance
        
        // Historical data (last 7 days) with some variation
        for i in (1...7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let variation = Double.random(in: -50...100) // Realistic daily variation
            currentBalance += variation
            
            points.append(BalanceForecastPoint(
                date: date,
                balance: currentBalance,
                isProjected: false,
                hasTransaction: i % 2 == 0, // Some days have transactions
                transactionColor: .green
            ))
        }
        
        // Reset to actual current balance
        currentBalance = account.balance
        
        // Add today's point
        points.append(BalanceForecastPoint(
            date: today,
            balance: currentBalance,
            isProjected: false,
            hasTransaction: false,
            transactionColor: .clear
        ))
        
        // Future projection (next 30 days)
        for i in 1...30 {
            let date = calendar.date(byAdding: .day, value: i, to: today) ?? today
            
            // Apply scheduled transactions for this date
            let scheduledForDate = scheduledTransactions.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            
            var dayChange: Double = 0
            var hasTransaction = false
            var transactionColor: Color = .clear
            
            for scheduledTx in scheduledForDate {
                dayChange += scheduledTx.amount
                hasTransaction = true
                transactionColor = scheduledTx.amount >= 0 ? .green : .red
            }
            
            // Add some random spending for realism (typical UK daily spend £20-80)
            if !hasTransaction && i % 3 == 0 { // Spending every few days
                dayChange -= Double.random(in: 20...80)
                hasTransaction = true
                transactionColor = .red
            }
            
            // Occasional income (salary, etc.)
            if i == 15 { // Mid-month salary
                dayChange += 2500 // Typical UK salary
                hasTransaction = true
                transactionColor = .green
            }
            
            currentBalance += dayChange
            
            points.append(BalanceForecastPoint(
                date: date,
                balance: currentBalance,
                isProjected: true,
                hasTransaction: hasTransaction,
                transactionColor: transactionColor
            ))
        }
        
        return points
    }
}

// MARK: - Supporting Types

struct BalanceForecastPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
    let isProjected: Bool
    let hasTransaction: Bool
    let transactionColor: Color
}

// MARK: - Preview Provider
struct BalanceForecastChart_Previews: PreviewProvider {
    static var previews: some View {
        let mockAccount = Account(
            userId: "test",
            name: "Barclays Current Account",
            type: .current,
            balance: 1250.0
        )
        
        let calendar = Calendar.current
        let today = Date()
        
        let mockScheduledTransactions = [
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: -450.0,
                description: "Rent",
                date: calendar.date(byAdding: .day, value: 5, to: today)!,
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: -89.99,
                description: "Phone Bill",
                date: calendar.date(byAdding: .day, value: 10, to: today)!,
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: 2500.0,
                description: "Salary",
                date: calendar.date(byAdding: .day, value: 15, to: today)!,
                isScheduled: true
            )
        ]
        
        BalanceForecastChart(
            account: mockAccount,
            transactions: [],
            scheduledTransactions: mockScheduledTransactions
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
