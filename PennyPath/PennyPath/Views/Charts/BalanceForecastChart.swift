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
    
    private var chartView: some View {
        Chart(filteredData, id: \.id) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(point.isProjected ? .blue.opacity(0.8) : .primary)
            .lineStyle(StrokeStyle(
                lineWidth: point.isProjected ? 2 : 3,
                dash: point.isProjected ? [5, 3] : []
            ))
            
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
                        let plotFrame = geometry[chartProxy.plotAreaFrame]
                        handleChartTap(at: location, resolvedFrame: plotFrame)
                    }
            }
        }
        .chartOverlay { chartProxy in
            GeometryReader { geometry in
                let resolvedFrame = geometry[chartProxy.plotAreaFrame]
                
                if let selectedPoint = selectedPoint {
                    let dateX = chartProxy.position(forX: selectedPoint.date) ?? 0
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 2)
                        .position(x: dateX, y: resolvedFrame.midY)
                        .animation(.easeInOut(duration: 0.2), value: selectedPoint.date)
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
    
    private func handleChartTap(at location: CGPoint, resolvedFrame: CGRect) {
        let relativeX = location.x - resolvedFrame.minX
        let plotWidth = resolvedFrame.width
        
        guard !filteredData.isEmpty else { return }
        
        let dataIndex = Int((relativeX / plotWidth) * Double(filteredData.count - 1))
        let clampedIndex = max(0, min(dataIndex, filteredData.count - 1))
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPoint = filteredData[clampedIndex]
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func generateBalanceForecast() -> [BalanceForecastPoint] {
        var points: [BalanceForecastPoint] = []
        let calendar = Calendar.current
        let today = Date()
        var currentBalance = account.balance
        
        for i in (1...7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let historicalBalance = currentBalance + Double.random(in: -200...100)
            
            points.append(BalanceForecastPoint(
                date: date,
                balance: historicalBalance,
                isProjected: false,
                transactionType: .none
            ))
        }
        
        points.append(BalanceForecastPoint(
            date: today,
            balance: currentBalance,
            isProjected: false,
            transactionType: .current
        ))
        
        var projectedBalance = currentBalance
        
        for i in 1...30 {
            let futureDate = calendar.date(byAdding: .day, value: i, to: today) ?? today
            let dayTransactions = scheduledTransactions.filter {
                calendar.isDate($0.date, inSameDayAs: futureDate)
            }
            
            for transaction in dayTransactions {
                projectedBalance += transaction.amount
                
                points.append(BalanceForecastPoint(
                    date: futureDate,
                    balance: projectedBalance,
                    isProjected: true,
                    transactionType: transaction.amount >= 0 ? .income : .expense
                ))
            }
            
            if dayTransactions.isEmpty {
                points.append(BalanceForecastPoint(
                    date: futureDate,
                    balance: projectedBalance,
                    isProjected: true,
                    transactionType: .none
                ))
            }
        }
        
        return points.sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Types

struct BalanceForecastPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
    let isProjected: Bool
    let transactionType: TransactionMarkerType
}

enum TransactionMarkerType {
    case none, current, income, expense, transfer
    
    var color: String {
        switch self {
        case .none: return "#000000"
        case .current: return "#007AFF"
        case .income: return "#34C759"
        case .expense: return "#FF3B30"
        case .transfer: return "#FF9500"
        }
    }
}
