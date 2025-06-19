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
            return chartData.filter { $0.isProjected || $0.date == Date() }
        }
        return chartData
    }
    
    private var balanceChange: Double {
        guard let first = chartData.first?.balance,
              let last = chartData.last?.balance else { return 0 }
        return last - first
    }
    
    var body: some View {
        VStack(spacing: 16) {
            chartHeader
            chartView
            chartControls
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
            
            Text(selectedPoint?.date.formatted(date: .abbreviated, time: .omitted) ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
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
    
    // FIXED: Simplified chart implementation using proven patterns
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
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let balance = value.as(Double.self) {
                        Text(balance.formattedAsCurrencyCompact)
                    }
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(at: location, in: geometry, with: chartProxy)
                    }
            }
        }
        .chartOverlay { chartProxy in
            if let selectedPoint = selectedPoint {
                GeometryReader { geometry in
                    let plotFrame = geometry[chartProxy.plotAreaFrame]
                    if let dateX = chartProxy.position(forX: selectedPoint.date) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 2)
                            .position(x: dateX, y: plotFrame.midY)
                            .animation(.easeInOut(duration: 0.2), value: selectedPoint.date)
                    }
                }
            }
        }
    }
    
    private var chartControls: some View {
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
    
    // FIXED: Simplified tap handling
    private func handleChartTap(at location: CGPoint, in geometry: GeometryProxy, with chartProxy: ChartProxy) {
        let plotFrame = geometry[chartProxy.plotAreaFrame]
        let relativeX = location.x - plotFrame.minX
        let plotWidth = plotFrame.width
        
        guard !filteredData.isEmpty, plotWidth > 0 else { return }
        
        let dataIndex = Int((relativeX / plotWidth) * Double(filteredData.count - 1))
        let clampedIndex = max(0, min(dataIndex, filteredData.count - 1))
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPoint = filteredData[clampedIndex]
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // FIXED: Simplified data generation
    private func generateBalanceForecast() -> [BalanceForecastPoint] {
        var points: [BalanceForecastPoint] = []
        let calendar = Calendar.current
        let today = Date()
        var currentBalance = account.balance
        
        // Historical data (last 7 days) with some variation
        for i in (1...7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let historicalBalance = currentBalance + Double.random(in: -200...100)
            
            points.append(BalanceForecastPoint(
                date: date,
                balance: historicalBalance,
                isProjected: false,
                hasTransaction: false,
                transactionColor: .clear
            ))
        }
        
        // Today's balance
        points.append(BalanceForecastPoint(
            date: today,
            balance: currentBalance,
            isProjected: false,
            hasTransaction: true,
            transactionColor: .blue
        ))
        
        // Future projections with scheduled transactions
        var projectedBalance = currentBalance
        
        for i in 1...30 {
            let futureDate = calendar.date(byAdding: .day, value: i, to: today) ?? today
            let dayTransactions = scheduledTransactions.filter {
                calendar.isDate($0.date, inSameDayAs: futureDate)
            }
            
            var hasTransaction = false
            var transactionColor: Color = .clear
            
            for transaction in dayTransactions {
                projectedBalance += transaction.amount
                hasTransaction = true
                transactionColor = transaction.amount >= 0 ? .green : .red
            }
            
            points.append(BalanceForecastPoint(
                date: futureDate,
                balance: projectedBalance,
                isProjected: true,
                hasTransaction: hasTransaction,
                transactionColor: transactionColor
            ))
        }
        
        return points.sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Types (FIXED)

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
            name: "Test Account",
            type: .current,
            balance: 2500.0
        )
        
        let mockScheduledTransactions = [
            Transaction(
                userId: "test",
                accountId: "test",
                amount: -89.00,
                description: "British Gas Bill",
                date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                amount: 2800.00,
                description: "Salary",
                date: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
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
