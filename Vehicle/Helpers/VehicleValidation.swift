import Foundation

// MARK: - Validation Result Type
struct ValidationResult {
    var isValid: Bool
    var message: String?
    
    static var valid: ValidationResult {
        ValidationResult(isValid: true, message: nil)
    }
    
    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, message: message)
    }
}

struct VehicleValidation {
    // MARK: - Basic Info Validation
    static func validateMake(_ make: String) -> ValidationResult {
        let trimmed = make.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? .invalid("Make cannot be empty") : .valid
    }
    
    static func validateModel(_ model: String) -> ValidationResult {
        let trimmed = model.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? .invalid("Model cannot be empty") : .valid
    }
    
    static func validateYear(_ year: Int) -> ValidationResult {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (year >= 1900 && year <= (currentYear + 1)) ? 
            .valid : 
            .invalid("Year must be between 1900 and \(currentYear + 1)")
    }
    
    static func validateNickname(_ nickname: String?) -> ValidationResult {
        guard let nickname = nickname else { return .valid }
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? .invalid("Nickname cannot be empty if provided") : .valid
    }
    
    // MARK: - Details Validation
    static func validateVIN(_ vin: String?, category: VehicleType, year: Int) -> ValidationResult {
        guard let vin = vin?.uppercased().trimmingCharacters(in: .whitespaces),
              !vin.isEmpty else { return .valid }  // Empty optional VIN is valid
        
        // Only apply modern VIN rules for automobiles 1981 and newer
        let requiresModernVIN = category.rawValue == "automobiles" && year >= 1981
        
        if requiresModernVIN {
            // Basic VIN validation rules for modern vehicles
            let validCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHJKLMNPRSTUVWXYZ")
            let invalidCharacters = CharacterSet(charactersIn: "IOQ")  // Commonly confused characters
            let vinCharacters = CharacterSet(charactersIn: vin)
            
            // Length check
            if vin.count != 17 {
                return .invalid("Modern VIN (1981+) must be exactly 17 characters (currently \(vin.count) characters)")
            }
            
            // Check for invalid characters (I, O, Q)
            if !vinCharacters.intersection(invalidCharacters).isEmpty {
                return .invalid("Modern VIN (1981+) cannot contain the letters I, O, or Q as they can be confused with numbers 1 and 0")
            }
            
            // Check for valid characters
            let invalidChars = vin.filter { !validCharacters.contains(UnicodeScalar(String($0))!) }
            if !invalidChars.isEmpty {
                return .invalid("Modern VIN (1981+) contains invalid characters: \(invalidChars). Only letters (except I,O,Q) and numbers are allowed")
            }
        } else {
            // Pre-1981 or non-automobile VIN validation
            // Basic validation to ensure reasonable length and no special characters
            let validCharacters = CharacterSet.alphanumerics
            
            if vin.count > 50 {
                return .invalid("VIN cannot exceed 50 characters")
            }
            
            // Check for valid characters
            let invalidChars = vin.filter { !validCharacters.contains(UnicodeScalar(String($0))!) }
            if !invalidChars.isEmpty {
                return .invalid("VIN contains invalid characters: \(invalidChars). Only letters and numbers are allowed")
            }
        }
        
        return .valid
    }
    
    static func validateSerialNumber(_ serialNumber: String?) -> ValidationResult {
        guard let serialNumber = serialNumber?.trimmingCharacters(in: .whitespaces),
              !serialNumber.isEmpty else { return .valid }  // Empty optional serial number is valid
        
        // Basic serial number validation - allow alphanumeric and common separators
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_/"))
        
        // Length check
        if serialNumber.count < 2 {
            return .invalid("Serial number must be at least 2 characters long")
        }
        
        if serialNumber.count > 50 {
            return .invalid("Serial number cannot exceed 50 characters (currently \(serialNumber.count) characters)")
        }
        
        // Check for valid characters
        let invalidChars = serialNumber.filter { !validCharacters.contains(UnicodeScalar(String($0))!) }
        if !invalidChars.isEmpty {
            return .invalid("Serial number contains invalid characters: \(invalidChars). Only letters, numbers, and - _ / are allowed")
        }
        
        return .valid
    }
    
    static func validateTrimLevel(_ trimLevel: String?) -> ValidationResult {
        guard let trimLevel = trimLevel?.trimmingCharacters(in: .whitespaces),
              !trimLevel.isEmpty else { return .valid }
        
        if trimLevel.count > 50 {
            return .invalid("Trim level cannot exceed 50 characters (currently \(trimLevel.count) characters)")
        }
        
        return .valid
    }
    
    static func validateNotes(_ notes: String?) -> ValidationResult {
        guard let notes = notes?.trimmingCharacters(in: .whitespaces),
              !notes.isEmpty else { return .valid }  // Empty optional notes is valid
        
        // Check length (reasonable limit for notes)
        let maxLength = 10000  // 10,000 characters should be sufficient for notes
        if notes.count > maxLength {
            return .invalid("Notes cannot exceed \(maxLength) characters (currently \(notes.count) characters)")
        }
        
        // Remove or replace problematic characters
        let invalidCharacters = CharacterSet.controlCharacters
            .subtracting(.newlines)  // Allow normal line breaks
        
        let containsInvalidChars = notes.unicodeScalars.contains { invalidCharacters.contains($0) }
        if containsInvalidChars {
            return .invalid("Notes contain invalid control characters. Please remove any special formatting.")
        }
        
        return .valid
    }
    
    // MARK: - Combined Validation
    static func validateVehicle(_ vehicle: Vehicle) -> ValidationResult {
        // Required fields
        let makeValidation = validateMake(vehicle.make)
        if !makeValidation.isValid {
            return makeValidation
        }
        
        let modelValidation = validateModel(vehicle.model)
        if !modelValidation.isValid {
            return modelValidation
        }
        
        let yearValidation = validateYear(vehicle.year)
        if !yearValidation.isValid {
            return yearValidation
        }
        
        // Optional fields with format requirements
        let nicknameValidation = validateNickname(vehicle.nickname)
        if !nicknameValidation.isValid {
            return nicknameValidation
        }
        
        let vinValidation = validateVIN(vehicle.vin, category: vehicle.category, year: vehicle.year)
        if !vinValidation.isValid {
            return vinValidation
        }
        
        let serialValidation = validateSerialNumber(vehicle.serialNumber)
        if !serialValidation.isValid {
            return serialValidation
        }
        
        let trimValidation = validateTrimLevel(vehicle.trimLevel)
        if !trimValidation.isValid {
            return trimValidation
        }
        
        let notesValidation = validateNotes(vehicle.notes)
        if !notesValidation.isValid {
            return notesValidation
        }
        
        return .valid
    }
}

// Event validation
struct EventValidation {
    static func validateDetails(_ details: String) -> ValidationResult {
        let trimmed = details.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return ValidationResult(isValid: false, message: "Details cannot be empty")
        }
        if trimmed.count > 2000 {
            return ValidationResult(isValid: false, message: "Details cannot exceed 2000 characters")
        }
        return ValidationResult(isValid: true, message: "")
    }
    
    static func validateDate(_ date: Date) -> ValidationResult {
        if date > Date() {
            return ValidationResult(isValid: false, message: "Date cannot be in the future")
        }
        return ValidationResult(isValid: true, message: "")
    }
    
    static func validateMileage(_ mileage: String, previousMileage: Decimal?) -> ValidationResult {
        guard !mileage.isEmpty else { return ValidationResult(isValid: true, message: "") }
        
        guard let mileageValue = Decimal(string: mileage.replacingOccurrences(of: ",", with: "")) else {
            return ValidationResult(isValid: false, message: "Please enter a valid number for mileage")
        }
        
        if mileageValue < Decimal.zero {
            return ValidationResult(isValid: false, message: "Mileage cannot be negative")
        }
        
        if let previous = previousMileage, mileageValue < previous {
            return ValidationResult(isValid: false, message: "Mileage cannot be less than the previous recorded mileage (\(previous))")
        }
        
        return ValidationResult(isValid: true, message: "")
    }
    
    static func validateHours(_ hours: String) -> ValidationResult {
        guard !hours.isEmpty else { return ValidationResult(isValid: true, message: "") }
        
        guard let hoursValue = Decimal(string: hours.replacingOccurrences(of: ",", with: "")) else {
            return ValidationResult(isValid: false, message: "Please enter a valid number for hours")
        }
        
        if hoursValue < Decimal.zero {
            return ValidationResult(isValid: false, message: "Hours cannot be negative")
        }
        
        if hoursValue > Decimal(1000000) {
            return ValidationResult(isValid: false, message: "Hours value seems unreasonably high")
        }
        
        return ValidationResult(isValid: true, message: "")
    }
    
    static func validateCost(_ cost: String) -> ValidationResult {
        guard !cost.isEmpty else { return ValidationResult(isValid: true, message: "") }
        
        guard let costValue = Decimal(string: cost.replacingOccurrences(of: ",", with: "")) else {
            return ValidationResult(isValid: false, message: "Please enter a valid number for cost")
        }
        
        if costValue < 0 {
            return ValidationResult(isValid: false, message: "Cost cannot be negative")
        }
        
        if costValue > 1000000000 {
            return ValidationResult(isValid: false, message: "Cost value seems unreasonably high")
        }
        
        return ValidationResult(isValid: true, message: "")
    }
}

// Ownership record validation
struct OwnershipValidation {
    static func validateDetails(_ details: String, type: OwnershipEventType) -> ValidationResult {
        let trimmed = details.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return ValidationResult(isValid: false, message: "Details cannot be empty")
        }
        if trimmed.count > 2000 {
            return ValidationResult(isValid: false, message: "Details cannot exceed 2000 characters")
        }
        
        // Type-specific validations
        switch type {
        case .sold:
            // Removed sold details validation requirement
            break
        case .purchased:
            // Removed purchase details validation requirement
            break
        default:
            break
        }
        
        return ValidationResult(isValid: true, message: "")
    }
    
    static func validateDate(_ date: Date) -> ValidationResult {
        if date > Date() {
            return ValidationResult(isValid: false, message: "Date cannot be in the future")
        }
        return ValidationResult(isValid: true, message: "")
    }
    
    static func validateRequiredFields(type: OwnershipEventType, cost: String) -> ValidationResult {
        // Cost is now optional for all record types
        return ValidationResult(isValid: true, message: "")
    }
}

// MARK: - Additional Validations
extension VehicleValidation {
    static func validateColor(_ color: String) -> ValidationResult {
        let validColors = ["black", "white", "gray", "red", "blue", "green", "brown", "orange", "yellow", "purple", "burgundy", "navy"]
        
        // Check if it's a valid predefined color
        if validColors.contains(color.lowercased()) {
            return .valid
        }
        
        // Check if it's a valid hex color
        let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        if color.range(of: hexPattern, options: .regularExpression) != nil {
            return .valid
        }
        
        return .invalid("Invalid color format. Please use a predefined color name or hex code (e.g., #FF0000)")
    }
    
    static func validateIcon(_ icon: String) -> ValidationResult {
        // Allow empty icon
        if icon.isEmpty {
            return .valid
        }
        
        // Check if it's a single emoji
        if icon.isSingleEmoji {
            return .valid
        }
        return .invalid("Please select a single emoji character")
    }
    
    static func validateCurrencyCode(_ code: String) -> ValidationResult {
        let validCodes = Locale.commonISOCurrencyCodes
        if validCodes.contains(code) {
            return .valid
        }
        return .invalid("Invalid currency code. Please use a valid ISO currency code (e.g., USD, EUR)")
    }
    
    static func validateEventDate(_ date: Date, vehicleYear: Int) -> ValidationResult {
        let calendar = Calendar.current
        
        // Check if date is in the future
        if date > Date() {
            return .invalid("Date cannot be in the future")
        }
        
        // Check if date is before vehicle manufacture
        let dateYear = calendar.component(.year, from: date)
        if dateYear < vehicleYear {
            return .invalid("Date cannot be before the vehicle's manufacture year (\(vehicleYear))")
        }
        
        // Check if date is unreasonably old
        if dateYear < 1900 {
            return .invalid("Date cannot be before 1900")
        }
        
        return .valid
    }
    
    static func validateMileageProgression(newMileage: Decimal, date: Date, vehicle: Vehicle) -> ValidationResult {
        guard let events = vehicle.events?.sorted(by: { $0.date < $1.date }) else {
            return .valid
        }
        
        // Find events before and after the new date
        let beforeEvents = events.filter { $0.date < date }
        let afterEvents = events.filter { $0.date > date }
        
        // Check against previous events
        if let lastBeforeEvent = beforeEvents.last,
           let lastMileage = lastBeforeEvent.mileage,
           newMileage < lastMileage {
            return .invalid("Mileage (\(newMileage)) cannot be less than previous recorded mileage (\(lastMileage)) from \(DateFormatter.localizedString(from: lastBeforeEvent.date, dateStyle: .medium, timeStyle: .none))")
        }
        
        // Check against future events
        if let firstAfterEvent = afterEvents.first,
           let nextMileage = firstAfterEvent.mileage,
           newMileage > nextMileage {
            return .invalid("Mileage (\(newMileage)) cannot be greater than next recorded mileage (\(nextMileage)) from \(DateFormatter.localizedString(from: firstAfterEvent.date, dateStyle: .medium, timeStyle: .none))")
        }
        
        return .valid
    }
}

// Helper extension for emoji validation
extension String {
    var isSingleEmoji: Bool {
        // Handle empty strings
        guard !isEmpty else { return false }
        
        // Get extended grapheme clusters (visible characters)
        let graphemeClusters = self.precomposedStringWithCompatibilityMapping
        guard graphemeClusters.count == 1 else { return false }
        
        // Get the first visible character
        let firstCharacter = graphemeClusters.first!
        
        // Check if it's a single character without modifiers
        if firstCharacter.unicodeScalars.count == 1 {
            let firstScalar = firstCharacter.unicodeScalars.first!
            
            // Check for circled letters (Unicode range: 0x24B6-0x24E9)
            if (0x24B6...0x24E9).contains(firstScalar.value) {
                return true
            }
            
            // Check for other special characters that should be allowed
            let specialRanges: [Range<UInt32>] = [
                // Basic emoji
                UInt32(0x1F300)..<UInt32(0x1FA00),  // Miscellaneous Symbols and Pictographs
                UInt32(0x2600)..<UInt32(0x2700),    // Miscellaneous Symbols
                UInt32(0x2700)..<UInt32(0x27C0),    // Dingbats
                UInt32(0x3000)..<UInt32(0x3040),    // CJK Symbols and Punctuation
                UInt32(0xFE00)..<UInt32(0xFE10),    // Variation Selectors
                UInt32(0x1F000)..<UInt32(0x1F030),  // Mahjong Tiles
                UInt32(0x1F0A0)..<UInt32(0x1F100),  // Playing Cards
                UInt32(0x1F100)..<UInt32(0x1F200),  // Enclosed Alphanumeric Supplement
                UInt32(0x1F200)..<UInt32(0x1F300),  // Enclosed Ideographic Supplement
                UInt32(0x1F600)..<UInt32(0x1F650),  // Emoticons
                UInt32(0x1F680)..<UInt32(0x1F700),  // Transport and Map Symbols
                UInt32(0x1F900)..<UInt32(0x1FA00),  // Supplemental Symbols and Pictographs
                // Circled numbers and letters
                UInt32(0x2460)..<UInt32(0x2500),    // Enclosed Alphanumerics
                UInt32(0x3200)..<UInt32(0x3300),    // Enclosed CJK Letters and Months
                // Other special symbols
                UInt32(0x2000)..<UInt32(0x2070),    // General Punctuation
                UInt32(0x2100)..<UInt32(0x2150),    // Letterlike Symbols
                UInt32(0x2190)..<UInt32(0x2200),    // Arrows
                UInt32(0x2200)..<UInt32(0x2300),    // Mathematical Operators
                UInt32(0x25A0)..<UInt32(0x2600),    // Geometric Shapes
                UInt32(0x2700)..<UInt32(0x27C0)     // Dingbats
            ]
            
            return specialRanges.contains { $0.contains(firstScalar.value) }
        }
        
        // Handle emoji with modifiers (skin tone, gender, etc.)
        let hasEmoji = firstCharacter.unicodeScalars.contains { scalar in
            scalar.properties.isEmoji && (scalar.value > 0x238C || firstCharacter.unicodeScalars.count > 1)
        }
        
        // Check for variation selectors and zero-width joiners
        let hasVariationSelectors = firstCharacter.unicodeScalars.contains { scalar in
            (0xFE00...0xFE0F).contains(scalar.value) || // Variation Selectors
            scalar.value == 0x200D                       // Zero-Width Joiner
        }
        
        return hasEmoji || hasVariationSelectors
    }
    
    var containsEmoji: Bool {
        contains { $0.isEmoji }
    }
}

extension Character {
    var isEmoji: Bool {
        // Get all unicode scalars for this character
        let scalars = unicodeScalars
        
        // Check for circled letters
        if let first = scalars.first, (0x24B6...0x24E9).contains(first.value) {
            return true
        }
        
        // Check if any scalar is an emoji
        for scalar in scalars {
            // Check if it's an emoji
            if scalar.properties.isEmoji {
                return true
            }
            
            // Check for variation selectors and zero-width joiners
            if (0xFE00...0xFE0F).contains(scalar.value) || // Variation Selectors
               scalar.value == 0x200D {                     // Zero-Width Joiner
                return true
            }
        }
        
        return false
    }
}

// MARK: - Decimal Validation and Formatting
extension VehicleValidation {
    static func validateAndFormatDecimal(_ value: String, fieldName: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid }
        
        // Remove any existing commas first
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        
        // Check for invalid characters (only allow digits and one decimal point)
        let validCharacters = CharacterSet(charactersIn: "0123456789.")
        let invalidChars = cleanValue.unicodeScalars.filter { !validCharacters.contains($0) }
        if !invalidChars.isEmpty {
            return .invalid("\(fieldName) can only contain numbers and decimal point")
        }
        
        // Check for valid decimal format
        guard let decimalValue = Decimal(string: cleanValue) else {
            return .invalid("Please enter a valid number for \(fieldName)")
        }
        
        // Check for negative values
        if decimalValue < 0 {
            return .invalid("\(fieldName) cannot be negative")
        }
        
        return .valid
    }
    
    static func formatDecimalForDisplay(_ value: Decimal?) -> String {
        guard let value = value else { return "" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0 // Only show decimal places if needed
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? ""
    }
    
    static func parseAndRoundDecimal(_ value: String) -> Decimal? {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        guard let decimal = Decimal(string: cleanValue) else { return nil }
        
        // Round to 2 decimal places
        var rounded = decimal
        var roundedValue = Decimal()
        NSDecimalRound(&roundedValue, &rounded, 2, .plain)
        return roundedValue
    }
}

// Update existing validation methods to use new decimal validation
extension EventValidation {
    static func validateMetrics(mileage: String, hours: String, cost: String) -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        // Validate mileage
        let mileageValidation = VehicleValidation.validateAndFormatDecimal(mileage, fieldName: "Mileage")
        if !mileageValidation.isValid {
            results.append(mileageValidation)
        }
        
        // Validate hours
        let hoursValidation = VehicleValidation.validateAndFormatDecimal(hours, fieldName: "Hours")
        if !hoursValidation.isValid {
            results.append(hoursValidation)
        }
        
        // Validate cost
        let costValidation = VehicleValidation.validateAndFormatDecimal(cost, fieldName: "Cost")
        if !costValidation.isValid {
            results.append(costValidation)
        }
        
        return results
    }
}

extension OwnershipValidation {
    static func validateMetrics(mileage: String, hours: String, cost: String) -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        // Validate mileage
        let mileageValidation = VehicleValidation.validateAndFormatDecimal(mileage, fieldName: "Mileage")
        if !mileageValidation.isValid {
            results.append(mileageValidation)
        }
        
        // Validate hours
        let hoursValidation = VehicleValidation.validateAndFormatDecimal(hours, fieldName: "Hours")
        if !hoursValidation.isValid {
            results.append(hoursValidation)
        }
        
        // Validate cost
        let costValidation = VehicleValidation.validateAndFormatDecimal(cost, fieldName: "Cost")
        if !costValidation.isValid {
            results.append(costValidation)
        }
        
        return results
    }
} 

