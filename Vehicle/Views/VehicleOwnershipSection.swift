import SwiftUI
import SwiftData
import Observation

struct VehicleOwnershipSection: View {
    let vehicle: Vehicle
    @Binding var showingOwnershipSheet: Bool
    @State private var displayLimit = 10
    @State private var showingAllRecords = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var sortedRecords: [OwnershipRecord]? {
        vehicle.ownershipRecords?.sorted { $0.date > $1.date }
    }
    
    private var displayedRecords: [OwnershipRecord]? {
        guard let records = sortedRecords else { return nil }
        return showingAllRecords ? records : Array(records.prefix(displayLimit))
    }
    
    private var totalRecords: Int {
        sortedRecords?.count ?? 0
    }
    
    private func toggleShowAllRecords() {
        if reduceMotion {
            showingAllRecords = true
        } else {
            withAnimation {
                showingAllRecords = true
            }
        }
    }
    
    var body: some View {
        Section {
            Button {
                HapticManager.shared.selectionChanged()
                showingOwnershipSheet = true
            } label: {
                Label("Add Ownership Record", systemImage: "plus")
            }
            
            if let records = displayedRecords, !records.isEmpty {
                ForEach(records) { record in
                    OwnershipRecordRowView(record: record, allRecords: records)
                }
                .onDelete { indexSet in
                    guard let index = indexSet.first,
                          let record = records[safe: index] else { return }
                    Task { @MainActor in
                        if reduceMotion {
                            vehicle.ownershipRecords?.removeAll { $0.id == record.id }
                        } else {
                            withAnimation {
                                vehicle.ownershipRecords?.removeAll { $0.id == record.id }
                            }
                        }
                    }
                }
                
                if !showingAllRecords && (sortedRecords?.count ?? 0) > displayLimit {
                    Button(action: {
                        Task { @MainActor in
                            toggleShowAllRecords()
                        }
                    }) {
                        Text("Show All \(totalRecords) Records")
                            .font(.subheadline)
                            .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Text("OWNERSHIP RECORDS")
                    .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                Spacer()
                if totalRecords > 0 {
                    Text("\(totalRecords)")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility5)
                }
            }
        }
        .onChange(of: vehicle.ownershipRecords?.count) { _, _ in
            Task { @MainActor in
                if vehicle.ownershipRecords?.isEmpty == true {
                    if reduceMotion {
                        showingAllRecords = false
                    } else {
                        withAnimation {
                            showingAllRecords = false
                        }
                    }
                }
            }
        }
    }
} 