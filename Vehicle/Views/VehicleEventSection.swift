import SwiftUI
import SwiftData
import Observation

struct VehicleEventSection: View {
    let vehicle: Vehicle
    @Binding var showingEventSheet: Bool
    @State private var displayLimit = 10
    @State private var showingAllEvents = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var sortedEvents: [Event]? {
        vehicle.events?.sorted { $0.date > $1.date }
    }
    
    private var displayedEvents: [Event]? {
        guard let events = sortedEvents else { return nil }
        return showingAllEvents ? events : Array(events.prefix(displayLimit))
    }
    
    private var totalEvents: Int {
        sortedEvents?.count ?? 0
    }
    
    private func toggleShowAllEvents() {
        if reduceMotion {
            showingAllEvents = true
        } else {
            withAnimation {
                showingAllEvents = true
            }
        }
    }
    
    var body: some View {
        Section {
            Button {
                HapticManager.shared.selectionChanged()
                showingEventSheet = true
            } label: {
                Label("Add Event", systemImage: "plus")
            }
            
            if let events = displayedEvents, !events.isEmpty {
                ForEach(events) { event in
                    EventRowView(event: event, allEvents: events)
                }
                .onDelete { indexSet in
                    guard let index = indexSet.first,
                          let event = events[safe: index] else { return }
                    Task { @MainActor in
                        if reduceMotion {
                            vehicle.events?.removeAll { $0.id == event.id }
                        } else {
                            withAnimation {
                                vehicle.events?.removeAll { $0.id == event.id }
                            }
                        }
                    }
                }
                
                if !showingAllEvents && (sortedEvents?.count ?? 0) > displayLimit {
                    Button(action: {
                        Task { @MainActor in
                            toggleShowAllEvents()
                        }
                    }) {
                        Text("Show All \(totalEvents) Events")
                            .font(.subheadline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Text("EVENTS")
                    .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                Spacer()
                if totalEvents > 0 {
                    Text("\(totalEvents)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                }
            }
        }
        .onChange(of: vehicle.events?.count) { _, _ in
            Task { @MainActor in
                if vehicle.events?.isEmpty == true {
                    if reduceMotion {
                        showingAllEvents = false
                    } else {
                        withAnimation {
                            showingAllEvents = false
                        }
                    }
                }
            }
        }
    }
} 