import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: [
        SortDescriptor(\Vehicle.year, order: .reverse),
        SortDescriptor(\Vehicle.make),
        SortDescriptor(\Vehicle.model)
    ]) private var vehicles: [Vehicle]
    @Query private var events: [Event]
    @Query private var ownershipRecords: [OwnershipRecord]
    
    @AppStorage(AppStorageKeys.vehicleSortOption) private var sortOption = VehicleSortOption.none.rawValue
    @AppStorage(AppStorageKeys.vehicleGroupOption) private var groupOption = VehicleGroupOption.none.rawValue
    @AppStorage(AppStorageKeys.showNicknamesInList) private var showNicknamesInList = true
    @AppStorage(AppStorageKeys.showIconsInList) private var showIconsInList = true
    
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: FormField?
    @State private var showingMessage = false
    @State private var message = ""
    @State private var showingResetSyncConfirmation = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var showingBackupConfirmation = false
    @State private var isCreatingBackup = false
    
    private let logger = AppLogger.shared
    private let networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        NavigationStack {
            Form {
                AppearanceSection(
                    sortOption: $sortOption,
                    groupOption: $groupOption,
                    showNicknamesInList: $showNicknamesInList,
                    showIconsInList: $showIconsInList
                )
                
                DataSection(
                    vehicles: vehicles,
                    events: events,
                    ownershipRecords: ownershipRecords,
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    showingExportSheet: $showingExportSheet,
                    exportURL: $exportURL,
                    isExporting: $isExporting,
                    showingBackupConfirmation: $showingBackupConfirmation,
                    isCreatingBackup: $isCreatingBackup,
                    onExportJSON: exportDataJSON,
                    onExportCSV: exportDataCSV,
                    onBackup: createBackup
                )
                
                AboutSection()
                
                SyncAndNetworkSection(
                    networkMonitor: networkMonitor,
                    showingResetSyncConfirmation: $showingResetSyncConfirmation
                )
            }
            .standardNavigationBar(title: "Settings")
            .standardFormStyle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        HapticManager.standardButtonTap()
                        dismiss()
                    }
                    .accessibilityLabel("Close settings")
                    .accessibilityHint("Return to the previous screen")
                }
            }
            .standardKeyboardDoneButton(focusedField: $focusedField)
            .alert("Delete All Records?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.standardButtonTap()
                }
                Button("Delete", role: .destructive) {
                    HapticManager.standardDelete()
                    deleteAllRecords()
                }
            } message: {
                Text("Are you sure you want to delete all vehicles, events, and ownership records? This action cannot be undone.")
            }
            .alert("Reset Sync State?", isPresented: $showingResetSyncConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.standardButtonTap()
                }
                Button("Reset", role: .destructive) {
                    HapticManager.standardDelete()
                    resetSyncState()
                }
            } message: {
                Text("This will reset the sync state and force a full sync with iCloud. Continue?")
            }
            .alert("Validation Error", isPresented: $showingError) {
                Button("OK") {
                    HapticManager.standardButtonTap()
                    showingError = false
                }
            } message: {
                Text(errorMessage)
            }
            .alert("Create Backup?", isPresented: $showingBackupConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.standardButtonTap()
                }
                Button("Create Backup") {
                    HapticManager.standardButtonTap()
                    createBackup()
                }
            } message: {
                Text("This will create a backup of your database. Backups are stored locally and the last 3 are kept.")
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url], filename: url.lastPathComponent)
                }
            }
            .alert("Success", isPresented: $showingMessage) {
                Button("OK") {
                    HapticManager.standardButtonTap()
                    showingMessage = false
                }
            } message: {
                Text(message)
            }
        }
    }
    
    private func exportDataJSON() {
        isExporting = true
        Task {
            do {
                let url = try await DataExportManager.shared.exportToJSON(vehicles: vehicles)
                await MainActor.run {
                    exportURL = url
                    showingExportSheet = true
                    isExporting = false
                    HapticManager.standardSuccess()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to export data: \(error.localizedDescription)"
                    showingError = true
                    isExporting = false
                    HapticManager.standardError()
                }
                logger.error("JSON export failed: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    private func exportDataCSV() {
        isExporting = true
        Task {
            do {
                let url = try await DataExportManager.shared.exportToCSV(vehicles: vehicles)
                await MainActor.run {
                    exportURL = url
                    showingExportSheet = true
                    isExporting = false
                    HapticManager.standardSuccess()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to export CSV: \(error.localizedDescription)"
                    showingError = true
                    isExporting = false
                    HapticManager.standardError()
                }
                logger.error("CSV export failed: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    private func createBackup() {
        isCreatingBackup = true
        Task {
            do {
                _ = try await DatabaseBackupManager.shared.createPreMigrationBackup()
                await MainActor.run {
                    isCreatingBackup = false
                    message = "Backup created successfully"
                    showingMessage = true
                    HapticManager.standardSuccess()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create backup: \(error.localizedDescription)"
                    showingError = true
                    isCreatingBackup = false
                    HapticManager.standardError()
                }
                logger.error("Backup failed: \(error.localizedDescription)", category: .database)
            }
        }
    }
    
    private func deleteAllRecords() {
        logger.info("Starting deletion of all records", category: .database)
        
        // Delete all events first to maintain referential integrity
        logger.debug("Deleting \(events.count) events", category: .database)
        for event in events {
            modelContext.delete(event)
        }
        
        // Delete all ownership records
        logger.debug("Deleting \(ownershipRecords.count) ownership records", category: .database)
        for record in ownershipRecords {
            modelContext.delete(record)
        }
        
        // Delete all vehicles
        logger.debug("Deleting \(vehicles.count) vehicles", category: .database)
        for vehicle in vehicles {
            modelContext.delete(vehicle)
        }
        
        HapticManager.standardSuccess()
        logger.info("Successfully deleted all records", category: .database)
    }
    
    private func resetSyncState() {
        networkMonitor.resetSyncState()
        HapticManager.standardSuccess()
        logger.info("Successfully reset sync state", category: .sync)
    }
}

// MARK: - Subviews

private struct AppearanceSection: View {
    @Binding var sortOption: String
    @Binding var groupOption: String
    @Binding var showNicknamesInList: Bool
    @Binding var showIconsInList: Bool
    
    var body: some View {
        Section {
            Picker("Sort Vehicles By", selection: $sortOption) {
                ForEach(VehicleSortOption.allCases, id: \.self) { option in
                    Text(option.displayName)
                        .tag(option.rawValue)
                }
            }
            .accessibilityLabel("Sort vehicles by")
            .accessibilityHint("Choose how to sort your vehicle list")
            
            Picker("Group Vehicles By", selection: $groupOption) {
                ForEach(VehicleGroupOption.allCases, id: \.self) { option in
                    Text(option.displayName)
                        .tag(option.rawValue)
                }
            }
            .accessibilityLabel("Group vehicles by")
            .accessibilityHint("Choose how to group your vehicle list")
            
            Toggle("Show Nicknames in Vehicle List", isOn: $showNicknamesInList)
                .accessibilityLabel("Show nicknames in vehicle list")
                .accessibilityHint("When enabled, displays vehicle nicknames instead of make and model")
            Toggle("Show Icon in Vehicle List & Title Bar", isOn: $showIconsInList)
                .accessibilityLabel("Show icons in vehicle list and title bar")
                .accessibilityHint("When enabled, displays emoji icons next to vehicle names")
        } header: {
            Text("APPEARANCE")
        }
    }
}

private struct DataSection: View {
    let vehicles: [Vehicle]
    let events: [Event]
    let ownershipRecords: [OwnershipRecord]
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingExportSheet: Bool
    @Binding var exportURL: URL?
    @Binding var isExporting: Bool
    @Binding var showingBackupConfirmation: Bool
    @Binding var isCreatingBackup: Bool
    let onExportJSON: () -> Void
    let onExportCSV: () -> Void
    let onBackup: () -> Void
    
    var body: some View {
        Section {
            LabeledContent {
                Text("\(vehicles.count)")
                    .foregroundStyle(.secondary)
            } label: {
                Text("Vehicles")
            }
            
            LabeledContent {
                Text("\(events.count)")
                    .foregroundStyle(.secondary)
            } label: {
                Text("Events")
            }
            
            LabeledContent {
                Text("\(ownershipRecords.count)")
                    .foregroundStyle(.secondary)
            } label: {
                Text("Ownership Records")
            }
            
            LabeledContent {
                Text(SchemaVersionManager.currentSchemaVersion)
                    .foregroundStyle(.secondary)
            } label: {
                Text("Data Version")
            }
            
            Button {
                onExportJSON()
            } label: {
                HStack {
                    Label("Export as JSON", systemImage: "doc.badge.arrow.up")
                    if isExporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isExporting || vehicles.isEmpty)
            .accessibilityLabel("Export as JSON")
            .accessibilityHint("Export all vehicle data as a JSON file for backup or transfer")
            
            Button {
                onExportCSV()
            } label: {
                HStack {
                    Label("Export as CSV", systemImage: "tablecells.badge.ellipsis")
                    if isExporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isExporting || vehicles.isEmpty)
            .accessibilityLabel("Export as CSV")
            .accessibilityHint("Export all vehicle data as a spreadsheet-compatible CSV file")
            
            Button {
                showingBackupConfirmation = true
            } label: {
                HStack {
                    Label("Create Backup", systemImage: "externaldrive.badge.plus")
                    if isCreatingBackup {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isCreatingBackup)
            .accessibilityLabel("Create backup")
            .accessibilityHint("Create a local backup copy of your database")
            
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete All Records", systemImage: "trash")
            }
            .accessibilityLabel("Delete all records")
            .accessibilityHint("Permanently delete all vehicles, events, and ownership records")
        } header: {
            Text("DATA")
        } footer: {
            Text("Export creates a file you can share or save. JSON preserves all data structure, CSV is spreadsheet-compatible. Backup creates a local copy of your database.")
        }
    }
}

private struct AboutSection: View {
    var body: some View {
        Section {
            Link(destination: URL(string: "https://www.genericgroup.net")!) {
                Label("Developer", systemImage: "person.fill")
                    .foregroundStyle(.primary)
                    .frame(height: 38)
            }
            .accessibilityLabel("Developer website")
            .accessibilityHint("Opens the developer website in your browser")
            
            Link(destination: URL(string: "https://www.genericgroup.net/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundStyle(.primary)
                    .frame(height: 38)
            }
            .accessibilityLabel("Privacy policy")
            .accessibilityHint("Opens the privacy policy in your browser")
            
            Link(destination: URL(string: "https://www.genericgroup.net/terms")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
                    .foregroundStyle(.primary)
                    .frame(height: 38)
            }
            .accessibilityLabel("Terms of use")
            .accessibilityHint("Opens the terms of use in your browser")
            
            Link(destination: URL(string: "https://www.genericgroup.net/contact")!) {
                Label("Contact Us", systemImage: "envelope.fill")
                    .foregroundStyle(.primary)
                    .frame(height: 38)
            }
            .accessibilityLabel("Contact us")
            .accessibilityHint("Opens the contact page in your browser")
            
            Link(destination: URL(string: "https://genericgroup.net/faq#vehicle-pro")!) {
                Label("FAQ", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.primary)
                    .frame(height: 38)
            }
            .accessibilityLabel("Frequently asked questions")
            .accessibilityHint("Opens the FAQ page in your browser")
            
            Button {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                SKStoreReviewController.requestReview(in: windowScene)
            } label: {
                Label("Rate App", systemImage: "star.fill")
                    .foregroundStyle(.primary)
                    .frame(height: 38)
            }
            .accessibilityLabel("Rate this app")
            .accessibilityHint("Opens the App Store to leave a review")
            
            LabeledContent {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    .foregroundStyle(.secondary)
            } label: {
                Text("Version")
            }
            .frame(height: 38)
            .accessibilityLabel("App version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
        } header: {
            Text("ABOUT")
        }
    }
}

private struct SyncAndNetworkSection: View {
    let networkMonitor: NetworkMonitor
    @Binding var showingResetSyncConfirmation: Bool
    
    var body: some View {
        Section {
            LabeledContent {
                HStack {
                    Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .foregroundStyle(networkMonitor.isConnected ? .green : .red)
                    Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                        .foregroundStyle(networkMonitor.isConnected ? .primary : .secondary)
                }
            } label: {
                Text("Network Status")
            }
            .accessibilityLabel("Network status: \(networkMonitor.isConnected ? "Connected" : "Disconnected")")
            
            LabeledContent {
                HStack {
                    Image(systemName: networkMonitor.isCloudKitAvailable ? "cloud" : "cloud.slash")
                        .foregroundStyle(networkMonitor.isCloudKitAvailable ? .blue : .red)
                    Text(networkMonitor.isCloudKitAvailable ? "Available" : "Unavailable")
                        .foregroundStyle(networkMonitor.isCloudKitAvailable ? .primary : .secondary)
                }
            } label: {
                Text("iCloud Status")
            }
            .accessibilityLabel("iCloud status: \(networkMonitor.isCloudKitAvailable ? "Available" : "Unavailable")")
            
            if let lastSync = networkMonitor.lastSyncAttempt {
                LabeledContent {
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                } label: {
                    Text("Last Sync")
                }
                .accessibilityLabel("Last sync attempt")
            }
            
            if networkMonitor.syncRetryCount > 0 {
                LabeledContent {
                    Text("\(networkMonitor.syncRetryCount)")
                        .foregroundStyle(.secondary)
                } label: {
                    Text("Retry Count")
                }
                .accessibilityLabel("Sync retry count: \(networkMonitor.syncRetryCount)")
            }
            
            Button {
                showingResetSyncConfirmation = true
            } label: {
                Label("Reset Sync State", systemImage: "arrow.clockwise")
            }
            .disabled(!networkMonitor.isConnected || !networkMonitor.isCloudKitAvailable)
            .accessibilityLabel("Reset sync state")
            .accessibilityHint("Clears sync tokens and triggers a fresh sync with iCloud")
        } header: {
            Text("SYNC & NETWORK")
        } footer: {
            Text("Reset Sync State clears local sync tokens and triggers a fresh sync with iCloud. This can help resolve sync issues but may take longer to complete.")
        }
    }
} 
