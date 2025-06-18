//
//  BalanceForecastChart.swift
//  PennyPath
//
//  Created by Robert Cobain on 18/06/2025.
//


import SwiftUI
import Charts

/// Interactive balance forecast chart showing 30-day projection with scheduled payments
struct BalanceForecastChart: View {
    let account: Account
    let transactions: [Transaction]
    let scheduledTransactions: [Transaction]
    
    @State private var selectedPoint: BalanceForecastPoint?
    @State private var showingProjectedOnly = false
    
    private var chartData: [BalanceForecastPoint] {
        ChartDataProcessor.generateBalanceForecast(
            account: account,
            transactions: transactions,
            scheduledTransactions: scheduledTransactions
        )
    }
    
    private var filteredData: [BalanceForecastPoint] {
        if showingProjectedOnly {
            return chartData.filter { $0.isProjected || $0.transactionType == .current }
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
            // Chart header with metrics
            chartHeader
            
            // Main chart
            chartView
            
            // Chart controls
            chartControls
        }
    }
    
    // MARK: - Chart Header
    
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
            
            // Balance change indicator
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
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart(filteredData) { point in
            // Main balance line
            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(point.isProjected ? .blue.opacity(0.8) : .primary)
            .lineStyle(StrokeStyle(
                lineWidth: point.isProjected ? 2 : 3,
                dash: point.isProjected ? [5, 3] : []
            ))
            
            // Area fill under the line
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        point.isProjected ? Color.blue.opacity(0.3) : Color.primary.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Special markers for significant points
            if point.transactionType != .none {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(Color(hex: point.transactionType.color))
                .symbolSize(point.transactionType == .current ? 100 : 60)
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
                        handleChartTap(at: location, geometry: geometry, chartProxy: chartProxy)
                    }
            }
        }
        .chartOverlay { chartProxy in
            // Selection indicator
            if let selectedPoint = selectedPoint {
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotAreaFrame {
                        let dateX = chartProxy.position(forX: selectedPoint.date) ?? 0
                        
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
    
    // MARK: - Chart Controls
    
    private var chartControls: some View {
        HStack {
            // View toggle
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
            
            // Legend
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
    
    // MARK: - Chart Interaction
    
    private func handleChartTap(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        let plotFrame = chartProxy.plotAreaFrame
        let relativeX = location.x - plotFrame.minX
        let plotWidth = plotFrame.width
        
        // Find the closest data point
        guard !filteredData.isEmpty else { return }
        
        let dataIndex = Int((relativeX / plotWidth) * Double(filteredData.count - 1))
        let clampedIndex = max(0, min(dataIndex, filteredData.count - 1))
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPoint = filteredData[clampedIndex]
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview Provider
struct BalanceForecastChart_Previews: PreviewProvider {
    static var previews: some View {
        let mockAccount = Account(
            userId: "test",
            name: "Barclays Current Account",
            type: .current,
            balance: 2850.75
        )
        
        let mockTransactions: [Transaction] = [
            Transaction(userId: "test", accountId: "acc-current", amount: -45.80, description: "Grocery shopping"),
            Transaction(userId: "test", accountId: "acc-current", amount: 2800.00, description: "Salary"),
            Transaction(userId: "test", accountId: "acc-current", amount: -120.00, description: "Utilities")
        ]
        
        let mockScheduled: [Transaction] = [
            Transaction(
                userId: "test",
                accountId: "acc-current",
                amount: -89.00,
                description: "British Gas Bill",
                date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "acc-current",
                amount: 2800.00,
                description: "Next Salary",
                date: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
                isScheduled: true
            )
        ]
        
        VStack(spacing: 20) {
            BalanceForecastChart(
                account: mockAccount,
                transactions: mockTransactions,
                scheduledTransactions: mockScheduled
            )
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}