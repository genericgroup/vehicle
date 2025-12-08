import Foundation

enum VehicleError: LocalizedError {
    case invalidMake
    case invalidModel
    case invalidYear
    case invalidDetails
    case invalidVIN
    case invalidLicensePlate
    case invalidMileage
    case invalidCost
    
    var errorDescription: String? {
        switch self {
        case .invalidMake:
            return "Make cannot be empty"
        case .invalidModel:
            return "Model cannot be empty"
        case .invalidYear:
            return "Year must be between 1900 and next year"
        case .invalidDetails:
            return "Details cannot be empty"
        case .invalidVIN:
            return "Invalid VIN format"
        case .invalidLicensePlate:
            return "Invalid license plate format"
        case .invalidMileage:
            return "Invalid mileage value"
        case .invalidCost:
            return "Invalid cost value"
        }
    }
} 