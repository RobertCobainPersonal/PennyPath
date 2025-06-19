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
        VStack(spacing: 16) {
            chartHeader
            
            if viewMode == .timeline {
                timelineView
            } else {
                calendarView
            }
            
            chartControls
        }
    }
    
    private var chartHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment Schedule")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let selectedPayment = selectedPayment {
                    selectedPaymentInfo
                } else {
                    defaultMetrics
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("30-Day Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(totalUpcoming.formattedAsCurrency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var defaultMetrics: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chartData.count) payments")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Next 30 days")
                .font(.caption)
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
            .cornerRadius(4)
        }
        .frame(height: 150)
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
                    if let amount = value.as(Double.self) {
                        Text(amount.formattedAsCurrencyCompact)
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
                        handleTimelineTap(at: location, in: geometry, with: chartProxy)
                    }
            }
        }
    }
    
    private var calendarView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(generateCalendarDays(), id: \.self) { date in
                calendarDayView(for: date)
            }
        }
        .frame(height: 200)
    }
    
    private func calendarDayView(for date: Date) -> some View {
        let paymentsOnDay = chartData.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let dayTotal = paymentsOnDay.reduce(0) { $0 + abs($1.amount) }
        let isToday = Calendar.current.isDateInToday(date)
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        
        return VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isCurrentMonth ? .primary : .secondary)
            
            if dayTotal > 0 {
                Circle()
                    .fill(paymentsOnDay.count > 1 ? Color.red : Color.orange)
                    .frame(width: 6, height: 6)
                
                Text(dayTotal.formattedAsCurrencyCompact)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isToday ? Color.blue.opacity(0.2) : Color.clear)
        )
        .onTapGesture {
            if let firstPayment = paymentsOnDay.first {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedPayment = selectedPayment?.id == firstPayment.id ? nil : firstPayment
                }
            }
        }
    }
    
    private var chartControls: some View {
        VStack(spacing: 12) {
            // View mode selector
            Picker("View Mode", selection: $viewMode) {
                ForEach(ScheduleViewMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Payment list
            if !chartData.isEmpty {
                paymentsList
            }
        }
    }
    
    private var paymentsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Payments")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(chartData.prefix(5)) { payment in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(payment.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(daysUntilText(for: payment.date))
                            .font(.caption)
                            .foregroundColor(daysUntilColor(for: payment.date))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(abs(payment.amount).formattedAsCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text(payment.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedPayment?.id == payment.id ? Color.blue.opacity(0.1) : Color.clear)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPayment = selectedPayment?.id == payment.id ? nil : payment
                    }
                }
            }
            
            if chartData.count > 5 {
                Text("+ \(chartData.count - 5) more payments")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    private func paymentColor(for payment: ScheduledPayment) -> Color {
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: payment.date).day ?? 0
        
        if daysUntil <= 0 {
            return .red // Overdue or due today
        } else if daysUntil <= 3 {
            return .orange // Due soon
        } else {
            return .blue // Future
        }
    }
    
    private func daysUntilText(for date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else if days > 1 {
            return "Due in \(days) days"
        } else {
            return "Overdue"
        }
    }
    
    private func daysUntilColor(for date: Date) -> Color {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days <= 0 {
            return .red
        } else if days <= 3 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    private func handleTimelineTap(at location: CGPoint, in geometry: GeometryProxy, with chartProxy: ChartProxy) {
        let plotFrame = geometry[chartProxy.plotAreaFrame]
        let relativeX = location.x - plotFrame.minX
        let plotWidth = plotFrame.width
        
        guard !chartData.isEmpty, plotWidth > 0 else { return }
        
        // Find the closest payment based on X position
        let dateRange = chartData.map { $0.date }
        guard let minDate = dateRange.min(), let maxDate = dateRange.max() else { return }
        
        let timeInterval = maxDate.timeIntervalSince(minDate)
        let relativeTime = (relativeX / plotWidth) * timeInterval
        let tappedDate = minDate.addingTimeInterval(relativeTime)
        
        // Find closest payment
        let closestPayment = chartData.min { payment1, payment2 in
            abs(payment1.date.timeIntervalSince(tappedDate)) < abs(payment2.date.timeIntervalSince(tappedDate))
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPayment = selectedPayment?.id == closestPayment?.id ? nil : closestPayment
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func generateCalendarDays() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return [] }
        
        var days: [Date] = []
        var date = monthInterval.start
        
        while date < monthInterval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
    
    private func generateScheduledPayments() -> [ScheduledPayment] {
        let calendar = Calendar.current
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        return scheduledTransactions
            .filter {
                $0.accountId == account.id &&
                $0.isScheduled &&
                $0.date <= thirtyDaysFromNow &&
                $0.amount < 0 // Only expenses/payments
            }
            .map { transaction in
                ScheduledPayment(
                    id: transaction.id,
                    description: transaction.description,
                    amount: transaction.amount,
                    date: transaction.date,
                    recurrence: transaction.recurrence
                )
            }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Supporting Types

struct ScheduledPayment: Identifiable {
    let id: String
    let description: String
    let amount: Double
    let date: Date
    let recurrence: RecurrenceType?
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
                amount: -89.00,
                description: "British Gas Bill",
                date: calendar.date(byAdding: .day, value: 3, to: today)!,
                isScheduled: true,
                recurrence: .monthly
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                amount: -125.00,
                description: "Council Tax",
                date: calendar.date(byAdding: .day, value: 7, to: today)!,
                isScheduled: true,
                recurrence: .monthly
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                amount: -45.00,
                description: "BT Broadband",
                date: calendar.date(byAdding: .day, value: 12, to: today)!,
                isScheduled: true,
                recurrence: .monthly
            ),
            Transaction(
                userId: "test",
                accountId: "test",
                amount: -320.50,
                description: "Car Finance",
                date: calendar.date(byAdding: .day, value: 15, to: today)!,
                isScheduled: true,
                recurrence: .monthly
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
