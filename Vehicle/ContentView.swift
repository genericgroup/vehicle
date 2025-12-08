//
//  ContentView.swift
//  Vehicle
//
//  Created by Andy Carlson on 1/20/25.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.addedDate, order: .reverse) private var vehicles: [Vehicle]
    @StateObject private var viewModel = ContentViewModel()
    @State private var searchText = ""
    @State private var selectedVehicle: Vehicle?
    @State private var _cachedSortedVehicles: [Vehicle]?
    @State private var _lastSortOption: VehicleSortOption?
    @State private var _lastSearchResults: [SearchResultItem]?
    @State private var hasInitialized = false
    
    @AppStorage("vehicleSortOption") private var sortOption = VehicleSortOption.none.rawValue
    @AppStorage("vehicleGroupOption") private var groupOption = VehicleGroupOption.none.rawValue
    
    private let logger = AppLogger.shared
    
    private var currentGroupOption: VehicleGroupOption {
        VehicleGroupOption(rawValue: groupOption) ?? .none
    }
    
    private var sortedVehicles: [Vehicle] {
        let option = VehicleSortOption(rawValue: sortOption) ?? .none
        
        // Use cached results if available and sort option hasn't changed
        if let cached = _cachedSortedVehicles, _lastSortOption == option {
            return cached
        }
        
        // Calculate new sorted results
        let sorted = vehicles.sorted { v1, v2 in
            if v1.isPinned != v2.isPinned {
                return v1.isPinned
            }
            
            switch option {
            case .none:
                return v1.addedDate > v2.addedDate
            case .year:
                return v1.year > v2.year
            case .make:
                return v1.make.localizedCaseInsensitiveCompare(v2.make) == .orderedAscending
            case .lastUpdated:
                let v1LastEventDate = v1.events?.max(by: { $0.date < $1.date })?.date
                let v1LastOwnershipDate = v1.ownershipRecords?.max(by: { $0.date < $1.date })?.date
                let v1Date = [v1LastEventDate, v1LastOwnershipDate, v1.addedDate].compactMap { $0 }.max() ?? v1.addedDate
                
                let v2LastEventDate = v2.events?.max(by: { $0.date < $1.date })?.date
                let v2LastOwnershipDate = v2.ownershipRecords?.max(by: { $0.date < $1.date })?.date
                let v2Date = [v2LastEventDate, v2LastOwnershipDate, v2.addedDate].compactMap { $0 }.max() ?? v2.addedDate
                
                return v1Date > v2Date
            case .category:
                return v1.category.displayName.localizedCaseInsensitiveCompare(v2.category.displayName) == .orderedAscending
            }
        }
        
        // Update cache in the next run loop to avoid view update conflicts
        Task { @MainActor in
            _cachedSortedVehicles = sorted
            _lastSortOption = option
        }
        
        return sorted
    }
    
    private func updateSortCache(_ sorted: [Vehicle], option: VehicleSortOption) {
        _cachedSortedVehicles = sorted
        _lastSortOption = option
    }
    
    private func clearCaches() {
        Task { @MainActor in
            _cachedSortedVehicles = nil
            _lastSortOption = nil
            _lastSearchResults = nil
        }
    }
    
    private var filteredVehicles: [Vehicle] {
        guard !searchText.isEmpty else { return sortedVehicles }
        
        return sortedVehicles.filter { vehicle in
            isVehicleMatchingSearch(vehicle)
        }
    }
    
    private func isVehicleMatchingSearch(_ vehicle: Vehicle) -> Bool {
        let makeMatch = vehicle.make.localizedCaseInsensitiveContains(searchText)
        let modelMatch = vehicle.model.localizedCaseInsensitiveContains(searchText)
        let nicknameMatch = vehicle.nickname?.localizedCaseInsensitiveContains(searchText) == true
        let categoryMatch = vehicle.category.displayName.localizedCaseInsensitiveContains(searchText)
        let subcategoryMatch = vehicle.subcategory?.displayName.localizedCaseInsensitiveContains(searchText) == true
        let typeMatch = vehicle.vehicleType?.displayName.localizedCaseInsensitiveContains(searchText) == true
        let yearMatch = String(vehicle.year).contains(searchText)
        let notesMatch = vehicle.notes?.localizedCaseInsensitiveContains(searchText) == true
        
        let vehicleMatch = makeMatch || modelMatch || nicknameMatch || 
                          categoryMatch || subcategoryMatch || typeMatch || yearMatch ||
                          notesMatch
        
        let eventsMatch = hasMatchingEvents(vehicle.events)
        let ownershipMatch = hasMatchingOwnershipRecords(vehicle.ownershipRecords)
        
        return vehicleMatch || eventsMatch || ownershipMatch
    }
    
    private func hasMatchingEvents(_ events: [Event]?) -> Bool {
        events?.contains { event in
            event.details?.localizedCaseInsensitiveContains(searchText) == true ||
            event.category.displayName.localizedCaseInsensitiveContains(searchText) ||
            event.subcategory.displayName.localizedCaseInsensitiveContains(searchText)
        } == true
    }
    
    private func hasMatchingOwnershipRecords(_ records: [OwnershipRecord]?) -> Bool {
        records?.contains { record in
            record.details?.localizedCaseInsensitiveContains(searchText) == true ||
            record.type.displayName.localizedCaseInsensitiveContains(searchText)
        } == true
    }
    
    private var searchResults: [SearchResultItem] {
        guard !searchText.isEmpty else { return [] }
        return _lastSearchResults ?? []
    }
    
    private func updateSearchResults() {
        guard !searchText.isEmpty else {
            _lastSearchResults = []
            return
        }
        _lastSearchResults = buildSearchResults()
    }
    
    private func buildSearchResults() -> [SearchResultItem] {
        var results: [SearchResultItem] = []
        
        for vehicle in vehicles {
            // Add matching vehicles
            if vehicle.displayName.localizedCaseInsensitiveContains(searchText) ||
               vehicle.notes?.localizedCaseInsensitiveContains(searchText) == true {
                results.append(.vehicle(vehicle))
            }
            
            // Add matching events
            if let events = vehicle.events {
                results.append(contentsOf: findMatchingEvents(in: events))
            }
            
            // Add matching ownership records
            if let records = vehicle.ownershipRecords {
                results.append(contentsOf: findMatchingOwnershipRecords(in: records))
            }
        }
        
        return results
    }
    
    private func findMatchingEvents(in events: [Event]) -> [SearchResultItem] {
        events.compactMap { event in
            if event.details?.localizedCaseInsensitiveContains(searchText) == true ||
               event.category.displayName.localizedCaseInsensitiveContains(searchText) ||
               event.subcategory.displayName.localizedCaseInsensitiveContains(searchText) {
                return SearchResultItem.event(event)
            }
            return nil
        }
    }
    
    private func findMatchingOwnershipRecords(in records: [OwnershipRecord]) -> [SearchResultItem] {
        records.compactMap { record in
            if record.details?.localizedCaseInsensitiveContains(searchText) == true ||
               record.type.displayName.localizedCaseInsensitiveContains(searchText) {
                return SearchResultItem.ownershipRecord(record)
            }
            return nil
        }
    }
    
    private var groupedVehicles: [(String, [Vehicle])] {
        VehicleDisplayHelper.groupVehicles(filteredVehicles, option: currentGroupOption)
    }
    
    @ViewBuilder
    private func vehicleList() -> some View {
        VehicleListView(
            vehicles: vehicles,
            filteredVehicles: filteredVehicles,
            groupedVehicles: groupedVehicles,
            searchResults: searchResults,
            selectedVehicle: $selectedVehicle,
            searchText: $searchText,
            groupOption: groupOption,
            viewModel: viewModel,
            modelContext: modelContext,
            logger: logger
        )
    }
    
    var body: some View {
        NavigationSplitView {
            vehicleList()
        } detail: {
            VehicleDetailContainer(selectedVehicle: selectedVehicle)
        }
        .sheet(isPresented: $viewModel.showingAddVehicle) {
            AddVehicleSheet(modelContext: modelContext)
        }
        .sheet(isPresented: $viewModel.showingAddEvent) {
            AddEventSheet(selectedVehicle: selectedVehicle, modelContext: modelContext)
        }
        .sheet(isPresented: $viewModel.showingAddOwnership) {
            AddOwnershipSheet(selectedVehicle: selectedVehicle, modelContext: modelContext)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsSheet()
        }
        .alert("No Vehicles", isPresented: $viewModel.showingNoVehiclesError) {
            NoVehiclesAlert(viewModel: viewModel)
        } message: {
            Text("You need to add a vehicle before you can add events or ownership records.")
        }
        .accessibilityElement(children: .contain)
        .task {
            if !hasInitialized {
                viewModel.setModelContext(modelContext)
                hasInitialized = true
            }
        }
        .onChange(of: vehicles) { _, newVehicles in
            Task { @MainActor in
                viewModel.updateVehiclesState(hasVehicles: !newVehicles.isEmpty)
                clearCaches()
            }
        }
        .onChange(of: sortOption) { _, _ in
            Task { @MainActor in
                _cachedSortedVehicles = nil
                _lastSortOption = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            Task { @MainActor in
                clearCaches()
                logger.info("Cleared caches due to memory warning", category: .general)
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            if oldValue != newValue {
                _lastSearchResults = buildSearchResults()
            }
        }
        .task {
            // Initialize search results
            if !searchText.isEmpty {
                _lastSearchResults = buildSearchResults()
            }
        }
    }
}

// MARK: - List View
private struct VehicleListView: View {
    let vehicles: [Vehicle]
    let filteredVehicles: [Vehicle]
    let groupedVehicles: [(String, [Vehicle])]
    let searchResults: [SearchResultItem]
    @Binding var selectedVehicle: Vehicle?
    @Binding var searchText: String
    let groupOption: String
    let viewModel: ContentViewModel
    let modelContext: ModelContext
    let logger: AppLogger
    
    var body: some View {
        Group {
            if vehicles.isEmpty {
                ContentUnavailableView("No Vehicles", 
                    systemImage: "car",
                    description: Text("Add your first vehicle to get started")
                )
            } else {
                vehicleList
            }
        }
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                AddMenuButton(vehicles: vehicles, viewModel: viewModel)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsButton(viewModel: viewModel)
            }
        }
    }
    
    private var vehicleList: some View {
        List(selection: $selectedVehicle) {
            VehicleListContent(
                selectedVehicle: $selectedVehicle,
                vehicles: vehicles,
                filteredVehicles: filteredVehicles,
                groupedVehicles: groupedVehicles,
                searchResults: searchResults,
                viewModel: viewModel,
                modelContext: modelContext,
                logger: logger
            )
        }
        .listStyle(.plain)
        .background(Color(.systemBackground))
        .scrollContentBackground(.hidden)
        .onChange(of: selectedVehicle) { _, _ in
            viewModel.triggerSelectionHaptic()
        }
        .searchable(text: $searchText, 
                   placement: .navigationBarDrawer(displayMode: .always), 
                   prompt: "Search vehicles, events, and records")
        .overlay {
            if !searchText.isEmpty && searchResults.isEmpty {
                ContentUnavailableView("No Results", 
                    systemImage: "magnifyingglass",
                    description: Text("Try searching for something else")
                )
            }
        }
    }
}

// MARK: - Detail Container
private struct VehicleDetailContainer: View {
    let selectedVehicle: Vehicle?
    
    var body: some View {
        if let selectedVehicle = selectedVehicle {
            VehicleDetailView(vehicle: selectedVehicle)
        } else {
            ContentUnavailableView("Select a Vehicle", 
                systemImage: "car",
                description: Text("Choose a vehicle from the list to view its details")
            )
            .accessibilityLabel("No Vehicle Selected")
            .accessibilityHint("Select a vehicle from the list to view its details")
        }
    }
}

// MARK: - Add Menu Button
private struct AddMenuButton: View {
    let vehicles: [Vehicle]
    let viewModel: ContentViewModel
    
    var body: some View {
        Menu {
            Button {
                viewModel.triggerAddHaptic()
                viewModel.showingAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "car.fill")
            }
            .accessibilityLabel("Add Vehicle")
            .accessibilityHint("Opens form to add a new vehicle")

            Button {
                viewModel.triggerAddHaptic()
                viewModel.showingAddEvent = true
            } label: {
                Label("Add Event", systemImage: "calendar.badge.plus")
            }
            .accessibilityLabel("Add Event")
            .accessibilityHint(vehicles.isEmpty ? "Disabled until you add a vehicle" : "Opens form to add a new event")
            .disabled(vehicles.isEmpty)
            
            Button {
                viewModel.triggerAddHaptic()
                viewModel.showingAddOwnership = true
            } label: {
                Label("Add Ownership Record", systemImage: "person.badge.plus")
            }
            .accessibilityLabel("Add Ownership Record")
            .accessibilityHint(vehicles.isEmpty ? "Disabled until you add a vehicle" : "Opens form to add a new ownership record")
            .disabled(vehicles.isEmpty)
        } label: {
            Label("Add", systemImage: "plus")
                .accessibilityLabel("Add Menu")
                .accessibilityHint("Opens menu with options to add vehicles, events, and ownership records")
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.triggerMediumImpactHaptic()
                })
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .privacySensitive(true)
        .onAppear {
            viewModel.prepareHaptics()
        }
    }
}

// MARK: - Settings Button
private struct SettingsButton: View {
    let viewModel: ContentViewModel
    
    var body: some View {
        Button {
            viewModel.triggerMediumImpactHaptic()
            viewModel.showingSettings = true
        } label: {
            Label("Settings", systemImage: "gear")
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens settings menu")
    }
}

// MARK: - Sheet Views
private struct AddVehicleSheet: View {
    let modelContext: ModelContext
    
    var body: some View {
        NavigationStack {
            AddVehicleView()
                .modelContext(modelContext)
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.visible)
        .accessibilityLabel("Add Vehicle Form")
    }
}

private struct AddEventSheet: View {
    let selectedVehicle: Vehicle?
    let modelContext: ModelContext
    
    var body: some View {
        NavigationStack {
            AddEventView(selectedVehicle: selectedVehicle)
                .modelContext(modelContext)
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.visible)
        .accessibilityLabel("Add Event Form")
    }
}

private struct AddOwnershipSheet: View {
    let selectedVehicle: Vehicle?
    let modelContext: ModelContext
    
    var body: some View {
        NavigationStack {
            AddOwnershipView(selectedVehicle: selectedVehicle)
                .modelContext(modelContext)
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.visible)
        .accessibilityLabel("Add Ownership Record Form")
    }
}

private struct SettingsSheet: View {
    var body: some View {
        NavigationStack {
            SettingsView()
                .interactiveDismissDisabled()
                .presentationDragIndicator(.visible)
        }
        .accessibilityLabel("Settings")
    }
}

// MARK: - Alert Content
private struct NoVehiclesAlert: View {
    let viewModel: ContentViewModel
    
    var body: some View {
        Group {
            Button("Add Vehicle") {
                viewModel.showingAddVehicle = true
            }
            .accessibilityHint("Opens form to add your first vehicle")
            
            Button("Cancel", role: .cancel) {}
                .accessibilityLabel("Cancel")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
