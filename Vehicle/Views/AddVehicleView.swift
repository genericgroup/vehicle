import SwiftUI
import SwiftData

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private let logger = AppLogger.shared
    private let years = Array(1900...Calendar.current.component(.year, from: Date())).reversed()
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var color = "Black"
    @State private var nickname = ""
    @State private var icon = "🚗"
    @State private var showingEmojiPicker = false
    
    @State private var category: VehicleType?
    @State private var subcategory: VehicleSubcategory?
    @State private var vehicleType: VehicleTypeDetail?
    
    @State private var trimLevel = ""
    @State private var vin = ""
    @State private var serialNumber = ""
    @State private var fuelType: FuelType = .gasoline
    @State private var engineType: EngineType = .i4
    @State private var driveType: DriveType = .twoWD
    @State private var transmissionType: TransmissionType = .automatic
    
    @State private var showingValidationError = false
    @State private var validationError: String?
    
    private func validateAndSave() {
        // Trim whitespace
        let trimmedMake = make.trimmingCharacters(in: .whitespaces)
        let trimmedModel = model.trimmingCharacters(in: .whitespaces)
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespaces)
        let trimmedTrimLevel = trimLevel.trimmingCharacters(in: .whitespaces)
        let trimmedVIN = vin.trimmingCharacters(in: .whitespaces)
        let trimmedSerialNumber = serialNumber.trimmingCharacters(in: .whitespaces)
        
        // Validate required fields
        let makeValidation = VehicleValidation.validateMake(trimmedMake)
        if !makeValidation.isValid {
            validationError = makeValidation.message ?? "Make cannot be empty"
            showingValidationError = true
            return
        }
        
        let modelValidation = VehicleValidation.validateModel(trimmedModel)
        if !modelValidation.isValid {
            validationError = modelValidation.message ?? "Model cannot be empty"
            showingValidationError = true
            return
        }
        
        let yearValidation = VehicleValidation.validateYear(year)
        if !yearValidation.isValid {
            validationError = yearValidation.message ?? "Year must be between 1900 and next year"
            showingValidationError = true
            return
        }
        
        if category == nil {
            validationError = "Category must be selected"
            showingValidationError = true
            return
        }
        
        // Validate color
        let colorValidation = VehicleValidation.validateColor(color)
        if !colorValidation.isValid {
            validationError = colorValidation.message ?? "Invalid color format"
            showingValidationError = true
            return
        }
        
        // Validate icon
        let iconValidation = VehicleValidation.validateIcon(icon)
        if !iconValidation.isValid {
            validationError = iconValidation.message ?? "Invalid icon"
            showingValidationError = true
            return
        }
        
        // Validate optional fields if provided
        if !trimmedNickname.isEmpty {
            let nicknameValidation = VehicleValidation.validateNickname(trimmedNickname)
            if !nicknameValidation.isValid {
                validationError = nicknameValidation.message ?? "Invalid nickname"
                showingValidationError = true
                return
            }
        }
        
        if !trimmedVIN.isEmpty {
            let vinValidation = VehicleValidation.validateVIN(trimmedVIN, category: category ?? .automobiles, year: year)
            if !vinValidation.isValid {
                validationError = vinValidation.message ?? "Invalid VIN format"
                showingValidationError = true
                return
            }
        }
        
        if !trimmedSerialNumber.isEmpty {
            let serialValidation = VehicleValidation.validateSerialNumber(trimmedSerialNumber)
            if !serialValidation.isValid {
                validationError = serialValidation.message ?? "Invalid serial number format"
                showingValidationError = true
                return
            }
        }
        
        if !trimmedTrimLevel.isEmpty {
            let trimValidation = VehicleValidation.validateTrimLevel(trimmedTrimLevel)
            if !trimValidation.isValid {
                validationError = trimValidation.message ?? "Invalid trim level format"
                showingValidationError = true
                return
            }
        }
        
        // All validations passed, create and save vehicle
        let vehicle = Vehicle(
            make: trimmedMake,
            model: trimmedModel,
            year: year,
            color: color,
            nickname: trimmedNickname.isEmpty ? nil : trimmedNickname,
            icon: icon,
            category: category ?? .automobiles,
            subcategory: subcategory,
            vehicleType: vehicleType,
            trimLevel: trimmedTrimLevel.isEmpty ? nil : trimmedTrimLevel,
            vin: trimmedVIN.isEmpty ? nil : trimmedVIN.uppercased(),
            serialNumber: trimmedSerialNumber.isEmpty ? nil : trimmedSerialNumber,
            fuelType: fuelType,
            engineType: engineType,
            driveType: driveType,
            transmission: transmissionType,
            notes: nil
        )
        
        modelContext.insert(vehicle)
        do {
            try modelContext.save()
            logger.info("Successfully saved new vehicle to database", category: .database)
            HapticManager.shared.notifySuccess()
            dismiss()
        } catch {
            logger.error("Failed to save vehicle: \(error.localizedDescription)", category: .database)
            HapticManager.shared.notifyError()
            validationError = "Failed to save vehicle: \(error.localizedDescription)"
            showingValidationError = true
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Make*") {
                        TextField("Required", text: $make)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Make*")
                            .accessibilityLabel("Vehicle make")
                            .accessibilityHint("Required. Enter the manufacturer name")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Model*") {
                        TextField("Required", text: $model)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Model*")
                            .accessibilityLabel("Vehicle model")
                            .accessibilityHint("Required. Enter the model name")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Year") {
                        Picker("", selection: $year) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year))
                                    .tag(year)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Vehicle year")
                        .accessibilityHint("Select the model year")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Color") {
                        ColorPickerView(selection: $color, logger: logger)
                    }
                    .frame(height: 38)
                    .accessibilityLabel("Vehicle color: \(color)")
                    .accessibilityHint("Tap to select a color")
                    
                    LabeledContent("Nickname") {
                        TextField("Optional", text: $nickname)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Nickname")
                            .accessibilityLabel("Vehicle nickname")
                            .accessibilityHint("Optional. Enter a nickname for this vehicle")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Icon") {
                        Button(action: { 
                            HapticManager.shared.selectionChanged()
                            showingEmojiPicker = true 
                        }) {
                            Text(icon)
                                .font(.title2)
                        }
                        .accessibilityLabel("Vehicle icon: \(icon)")
                        .accessibilityHint("Tap to select an emoji icon")
                    }
                    .frame(height: 38)
                } header: {
                    Text("BASIC INFORMATION")
                } footer: {
                    Text("* Required")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    LabeledContent("Category*") {
                        Picker("", selection: $category) {
                            Text("Select Category").tag(nil as VehicleType?)
                            ForEach(VehicleType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type as VehicleType?)
                            }
                        }
                        .accessibilityIdentifier("Category*")
                        .accessibilityLabel("Vehicle category")
                        .accessibilityHint("Required. Select the type of vehicle")
                    }
                    .frame(height: 38)
                    
                    if let selectedCategory = category {
                        LabeledContent("Subcategory") {
                            Picker("", selection: $subcategory) {
                                Text("Not Set").tag(nil as VehicleSubcategory?)
                                ForEach(selectedCategory.subcategories, id: \.self) { subcategory in
                                    Text(subcategory.displayName).tag(subcategory as VehicleSubcategory?)
                                }
                            }
                            .accessibilityLabel("Vehicle subcategory")
                            .accessibilityHint("Optional. Select a more specific category")
                        }
                        .frame(height: 38)
                        
                        if let selectedSubcategory = subcategory {
                            LabeledContent("Type") {
                                Picker("", selection: $vehicleType) {
                                    Text("Not Set").tag(nil as VehicleTypeDetail?)
                                    ForEach(selectedSubcategory.types, id: \.self) { type in
                                        Text(type.displayName).tag(type as VehicleTypeDetail?)
                                    }
                                }
                                .accessibilityLabel("Vehicle type")
                                .accessibilityHint("Optional. Select the specific vehicle type")
                            }
                            .frame(height: 38)
                        }
                    }
                } header: {
                    Text("CATEGORIZATION")
                } footer: {
                    Text("* Required")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section("DETAILS") {
                    LabeledContent("Trim Level") {
                        TextField("Optional", text: $trimLevel)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Trim level")
                            .accessibilityHint("Optional. Enter the trim level like LX, EX, or Sport")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("VIN") {
                        TextField("Optional", text: $vin)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .accessibilityLabel("Vehicle identification number")
                            .accessibilityHint("Optional. Enter the 17-character VIN")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Serial Number") {
                        TextField("Optional", text: $serialNumber)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .accessibilityLabel("Serial number")
                            .accessibilityHint("Optional. Enter the serial number for non-automobile vehicles")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Fuel Type") {
                        Picker("", selection: $fuelType) {
                            ForEach(FuelType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .accessibilityLabel("Fuel type")
                        .accessibilityHint("Select the type of fuel this vehicle uses")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Engine Type") {
                        Picker("", selection: $engineType) {
                            ForEach(EngineType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .accessibilityLabel("Engine type")
                        .accessibilityHint("Select the engine configuration")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Drive Type") {
                        Picker("", selection: $driveType) {
                            ForEach(DriveType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .accessibilityLabel("Drive type")
                        .accessibilityHint("Select the drivetrain configuration")
                    }
                    .frame(height: 38)
                    
                    LabeledContent("Transmission") {
                        Picker("", selection: $transmissionType) {
                            ForEach(TransmissionType.allTypes, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .accessibilityLabel("Transmission type")
                        .accessibilityHint("Select automatic or manual transmission")
                    }
                    .frame(height: 38)
                }
            }
            .navigationTitle("Add Vehicle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                    .accessibilityIdentifier("Cancel")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        validateAndSave()
                    }
                    .accessibilityIdentifier("Save")
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPicker(selectedEmoji: $icon)
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK") {
                    showingValidationError = false
                }
            } message: {
                Text(validationError ?? "Invalid input")
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

struct ViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    AddVehicleView()
        .modelContainer(for: Vehicle.self, inMemory: true)
} 