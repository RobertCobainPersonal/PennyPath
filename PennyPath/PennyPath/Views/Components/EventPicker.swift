//
//  EventPicker.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//


//
//  EventPicker.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

/// Reusable event picker component for transaction tagging
/// Used in AddTransaction, EditTransaction, and bulk transaction editing
struct EventPicker: View {
    @EnvironmentObject var appStore: AppStore
    @Binding var selectedEventId: String
    let isRequired: Bool
    let showCreateNew: Bool
    let placeholder: String
    
    init(
        selectedEventId: Binding<String>,
        isRequired: Bool = false,
        showCreateNew: Bool = true,
        placeholder: String = "Select Event"
    ) {
        self._selectedEventId = selectedEventId
        self.isRequired = isRequired
        self.showCreateNew = showCreateNew
        self.placeholder = placeholder
    }
    
    private var selectedEvent: Event? {
        appStore.events.first { $0.id == selectedEventId }
    }
    
    private var activeEvents: [Event] {
        appStore.events.filter { $0.isActive }.sorted { $0.name < $1.name }
    }
    
    private var pastEvents: [Event] {
        appStore.events.filter { !$0.isActive }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        Menu {
            if !isRequired {
                Button("No Event") {
                    selectedEventId = ""
                }
                
                if !appStore.events.isEmpty {
                    Divider()
                }
            }
            
            // Active events section
            if !activeEvents.isEmpty {
                Section("Active Events") {
                    ForEach(activeEvents) { event in
                        eventMenuItem(event: event)
                    }
                }
            }
            
            // Past events section (if any exist and we have active events)
            if !pastEvents.isEmpty && !activeEvents.isEmpty {
                Section("Past Events") {
                    ForEach(pastEvents) { event in
                        eventMenuItem(event: event)
                    }
                }
            } else if !pastEvents.isEmpty {
                // If no active events, just show past events without section
                ForEach(pastEvents) { event in
                    eventMenuItem(event: event)
                }
            }
            
            // Create new event option
            if showCreateNew {
                if !appStore.events.isEmpty {
                    Divider()
                }
                
                Button(action: {
                    // TODO: Navigate to create event
                    print("➕ Create new event tapped")
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Create New Event")
                    }
                }
            }
        } label: {
            pickerLabel
        }
    }
    
    private func eventMenuItem(event: Event) -> some View {
        Button(action: {
            selectedEventId = event.id
        }) {
            HStack {
                Image(systemName: event.icon)
                    .foregroundColor(Color(hex: event.color))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .fontWeight(.medium)
                    
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if event.id == selectedEventId {
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var pickerLabel: some View {
        HStack {
            if let event = selectedEvent {
                Image(systemName: event.icon)
                    .foregroundColor(Color(hex: event.color))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(placeholder)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

/// Compact event picker for inline use
struct CompactEventPicker: View {
    @Binding var selectedEventId: String
    let placeholder: String
    
    init(selectedEventId: Binding<String>, placeholder: String = "Event") {
        self._selectedEventId = selectedEventId
        self.placeholder = placeholder
    }
    
    var body: some View {
        EventPicker(
            selectedEventId: $selectedEventId,
            isRequired: false,
            showCreateNew: false,
            placeholder: placeholder
        )
        .frame(height: 44) // Compact height
    }
}

/// Event picker with section headers and descriptions
struct EventPickerWithHeader: View {
    @Binding var selectedEventId: String
    let title: String
    let subtitle: String?
    
    init(selectedEventId: Binding<String>, title: String = "Event (Optional)", subtitle: String? = nil) {
        self._selectedEventId = selectedEventId
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Manage") {
                    // TODO: Navigate to event management
                    print("📝 Manage events tapped")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            EventPicker(selectedEventId: $selectedEventId)
            
            // Show selected event details
            if let selectedEvent = selectedEvent {
                selectedEventDetails(event: selectedEvent)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @EnvironmentObject var appStore: AppStore
    
    private var selectedEvent: Event? {
        appStore.events.first { $0.id == selectedEventId }
    }
    
    private func selectedEventDetails(event: Event) -> some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
                .font(.caption)
            
            Text(event.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let startDate = event.startDate {
                Text(startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 4)
    }
}

/// Event status badge for showing event active/past status
struct EventStatusBadge: View {
    let event: Event
    
    var body: some View {
        Text(event.isActive ? "Active" : "Past")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(event.isActive ? .green : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(event.isActive ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
            )
    }
}

// MARK: - Preview Provider
struct EventPicker_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppStore = AppStore()
        
        ScrollView {
            VStack(spacing: 20) {
                // Standard event picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Event Picker")
                        .font(.headline)
                    
                    EventPicker(selectedEventId: .constant("event-kitchen"))
                }
                
                Divider()
                
                // Event picker with header
                EventPickerWithHeader(
                    selectedEventId: .constant("event-paris"),
                    title: "Tag to Event",
                    subtitle: "Group transactions by trips, projects, or occasions"
                )
                
                Divider()
                
                // Compact event picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compact Event Picker")
                        .font(.headline)
                    
                    CompactEventPicker(
                        selectedEventId: .constant("event-golf"),
                        placeholder: "Select Event"
                    )
                }
                
                Divider()
                
                // Required event picker (no "None" option)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Required Event Picker")
                        .font(.headline)
                    
                    EventPicker(
                        selectedEventId: .constant(""),
                        isRequired: true,
                        placeholder: "Must select an event"
                    )
                }
                
                Divider()
                
                // Event status badges
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Status Badges")
                        .font(.headline)
                    
                    HStack {
                        EventStatusBadge(event: Event(
                            userId: "test",
                            name: "Active Event",
                            isActive: true
                        ))
                        
                        EventStatusBadge(event: Event(
                            userId: "test",
                            name: "Past Event",
                            isActive: false
                        ))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .environmentObject(mockAppStore)
    }
}