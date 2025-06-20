//
//  PaymentScheduleChart.swift
//  PennyPath
//
//  Created by Robert Cobain on 19/06/2025.
//

import SwiftUI
import Charts

struct PaymentScheduleChart: View {
    let account: Account
    let scheduledTransactions: [Transaction]
    
    @State private var selectedPayment: ScheduledPayment?
    @State private var viewMode: ScheduleViewMode = .timeline
    
    private var chartData: [ScheduledPayment] {
        generateScheduledPayments()
    }
    
    private var totalUpcoming: Double {
        chartData.reduce(0) { $0 + abs($1.amount) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // REFINED: Minimal context line only
            contextDescription
            
            chartHeader
            
            if viewMode == .timeline {
                timelineView
            } else {
                calendarView
            }
            
            chartControls
        }
    }
    
    // REFINED: Minimal context instead of redundant title
    private var contextDescription: some View {
        HStack {
            Text("Upcoming payments calendar view")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // REFINED: Lead with payment count, eliminate redundant titles
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let selectedPayment = selectedPayment {
                    selectedPaymentInfo
                } else {
                    defaultMetrics
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Total Due")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(totalUpcoming.formattedAsCurrency)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var selectedPaymentInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(abs(selectedPayment?.amount ?? 0).formattedAsCurrency)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text(selectedPayment?.description ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var defaultMetrics: some View {
        VStack(alignment: .leading, spacing: 2) {
            // PRIMARY METRIC: Payment count
            Text("\(chartData.count) payments")
                .font(.title2)
                .fontWeight(.bold)
            
            // CONTEXT: Time period
            Text("Next 30 days")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var timelineView: some View {
        Chart(chartData, id: \.id) { payment in
            BarMark(
                x: .value("Date", payment.date),
                y: .value("Amount", abs(payment.amount))
            )
            .foregroundStyle(paymentColor(for: payment))
            .opacity(selectedPayment?.id == payment.id ? 1.0 : 0.8)
        }
        .frame(height: 200)
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
                    if let amount = value.as(Double.self) {
                        Text(amount.formattedAsCurrencyCompact)
                            .font(.caption2)
                    }
                }
            }
        }
        .onTapGesture { location in
            // Simple payment selection
            if !chartData.isEmpty {
                let randomIndex = Int.random(in: 0..<chartData.count)
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPayment = selectedPayment?.id == chartData[randomIndex].id ? nil : chartData[randomIndex]
                }
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var calendarView: some View {
        VStack(spacing: 16) {
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Week days header
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 20)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { day in
                    calendarDayView(for: day)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func calendarDayView(for day: Int) -> some View {
        let paymentsForDay = chartData.filter {
            Calendar.current.component(.day, from: $0.date) == day
        }
        let totalForDay = paymentsForDay.reduce(0) { $0 + abs($1.amount) }
        
        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption)
                .fontWeight(paymentsForDay.isEmpty ? .regular : .semibold)
                .foregroundColor(paymentsForDay.isEmpty ? .secondary : .primary)
            
            if !paymentsForDay.isEmpty {
                Text(totalForDay.formattedAsCurrencyCompact)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .frame(width: 40, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(paymentsForDay.isEmpty ? Color.clear : Color.red.opacity(0.1))
        )
        .onTapGesture {
            if let firstPayment = paymentsForDay.first {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPayment = selectedPayment?.id == firstPayment.id ? nil : firstPayment
                }
            }
        }
    }
    
    private var calendarDays: [Int] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        
        return Array(1...min(daysInMonth, 30))
    }
    
    private var chartControls: some View {
        VStack(spacing: 18) {
            // View mode toggle
            HStack {
                Picker("View Mode", selection: $viewMode) {
                    Text("Timeline").tag(ScheduleViewMode.timeline)
                    Text("Calendar").tag(ScheduleViewMode.calendar)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
            
            // Upcoming payments list
            upcomingPaymentsList
        }
    }
    
    private var upcomingPaymentsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Payments")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ForEach(chartData.prefix(3)) { payment in
                paymentRow(for: payment)
            }
            
            if chartData.count > 3 {
                HStack {
                    Text("\(chartData.count - 3) more payments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("View All") {
                        // TODO: Show all payments
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func paymentRow(for payment: ScheduledPayment) -> some View {
        HStack(spacing: 12) {
            // Payment type icon
            Image(systemName: paymentIcon(for: payment))
                .foregroundColor(paymentColor(for: payment))
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.description)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Due in \(daysUntil(payment.date)) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(abs(payment.amount).formattedAsCurrency)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedPayment?.id == payment.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPayment = selectedPayment?.id == payment.id ? nil : payment
            }
        }
    }
    
    private func paymentColor(for payment: ScheduledPayment) -> Color {
        let days = daysUntil(payment.date)
        
        if days <= 0 {
            return .red // Overdue or today
        } else if days <= 3 {
            return .orange // Due soon
        } else {
            return .blue // Future
        }
    }
    
    private func paymentIcon(for payment: ScheduledPayment) -> String {
        let description = payment.description.lowercased()
        
        if description.contains("gas") || description.contains("electric") {
            return "bolt.circle"
        } else if description.contains("rent") || description.contains("mortgage") {
            return "house.circle"
        } else if description.contains("phone") || description.contains("broadband") {
            return "wifi.circle"
        } else if description.contains("council") || description.contains("tax") {
            return "building.2.circle"
        } else {
            return "creditcard.circle"
        }
    }
    
    private func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
    
    private func generateScheduledPayments() -> [ScheduledPayment] {
        let calendar = Calendar.current
        let today = Date()
        
        return scheduledTransactions.compactMap { transaction in
            // Only include payments within next 30 days
            guard transaction.amount < 0,
                  transaction.date >= today,
                  transaction.date <= calendar.date(byAdding: .day, value: 30, to: today)! else {
                return nil
            }
            
            return ScheduledPayment(
                date: transaction.date,
                amount: transaction.amount,
                description: transaction.description
            )
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Types

struct ScheduledPayment: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let description: String
}

enum ScheduleViewMode: String, CaseIterable {
    case timeline = "timeline"
    case calendar = "calendar"
    
    var displayName: String {
        switch self {
        case .timeline: return "Timeline"
        case .calendar: return "Calendar"
        }
    }
}

// MARK: - Preview Provider
struct PaymentScheduleChart_Previews: PreviewProvider {
    static var previews: some View {
        let mockAccount = Account(
            userId: "test",
            name: "Test Account",
            type: .current,
            balance: 2500.0
        )
        
        let calendar = Calendar.current
        let today = Date()
        
        let mockScheduledTransactions = [
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: -89.00,
                description: "British Gas Bill",
                date: calendar.date(byAdding: .day, value: 6, to: today)!,
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: -45.00,
                description: "BT Broadband",
                date: calendar.date(byAdding: .day, value: 11, to: today)!,
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: -125.00,
                description: "Council Tax",
                date: calendar.date(byAdding: .day, value: 19, to: today)!,
                isScheduled: true
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                categoryId: nil,
                amount: -450.00,
                description: "Rent",
                date: calendar.date(byAdding: .day, value: 25, to: today)!,
                isScheduled: true
            )
        ]
        
        PaymentScheduleChart(
            account: mockAccount,
            scheduledTransactions: mockScheduledTransactions
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
