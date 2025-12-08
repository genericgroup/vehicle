import SwiftUI
import SwiftData

// MARK: - Type Definitions
struct VehicleTypeDetail: Hashable {
    let name: String
    let displayName: String
}

struct VehicleSubcategory: Hashable {
    let name: String
    let displayName: String
    let types: [VehicleTypeDetail]
}

struct VehicleType: Hashable {
    let rawValue: String
    let displayName: String
    let subcategories: [VehicleSubcategory]
    
    private init(rawValue: String, displayName: String, subcategories: [VehicleSubcategory]) {
        self.rawValue = rawValue
        self.displayName = displayName
        self.subcategories = subcategories
    }
    
    static let automobiles = VehicleType(
        rawValue: "automobiles",
        displayName: "Automobiles",
        subcategories: [
            VehicleSubcategory(name: "car", displayName: "Car", types: [
                VehicleTypeDetail(name: "compact", displayName: "Compact"),
                VehicleTypeDetail(name: "sedan", displayName: "Sedan"),
                VehicleTypeDetail(name: "coupe", displayName: "Coupe"),
                VehicleTypeDetail(name: "hatchback", displayName: "Hatchback"),
                VehicleTypeDetail(name: "convertible", displayName: "Convertible"),
                VehicleTypeDetail(name: "sports_car", displayName: "Sports Car"),
                VehicleTypeDetail(name: "classic_car", displayName: "Classic Car")
            ]),
            VehicleSubcategory(name: "suv", displayName: "SUV", types: [
                VehicleTypeDetail(name: "compact", displayName: "Compact"),
                VehicleTypeDetail(name: "midsize", displayName: "Midsize"),
                VehicleTypeDetail(name: "fullsize", displayName: "Full-size"),
                VehicleTypeDetail(name: "luxury", displayName: "Luxury")
            ]),
            VehicleSubcategory(name: "pickup_truck", displayName: "Pickup Truck", types: [
                VehicleTypeDetail(name: "pickup_light", displayName: "Pickup (Light-Duty)"),
                VehicleTypeDetail(name: "pickup_heavy", displayName: "Pickup (Heavy-Duty)"),
                VehicleTypeDetail(name: "flatbed", displayName: "Flatbed"),
                VehicleTypeDetail(name: "utility", displayName: "Utility")
            ]),
            VehicleSubcategory(name: "van", displayName: "Van", types: [
                VehicleTypeDetail(name: "passenger", displayName: "Passenger Van"),
                VehicleTypeDetail(name: "cargo", displayName: "Cargo Van"),
                VehicleTypeDetail(name: "minivan", displayName: "Minivan")
            ])
        ]
    )
    
    static let motorcycles = VehicleType(
        rawValue: "motorcycles",
        displayName: "Motorcycles",
        subcategories: [
            VehicleSubcategory(name: "street", displayName: "Street", types: [
                VehicleTypeDetail(name: "naked", displayName: "Naked"),
                VehicleTypeDetail(name: "standard", displayName: "Standard"),
                VehicleTypeDetail(name: "electric", displayName: "Electric")
            ]),
            VehicleSubcategory(name: "sport", displayName: "Sport", types: [
                VehicleTypeDetail(name: "supersport", displayName: "Supersport"),
                VehicleTypeDetail(name: "hyperbike", displayName: "Hyperbike"),
                VehicleTypeDetail(name: "track", displayName: "Track-Only")
            ]),
            VehicleSubcategory(name: "touring", displayName: "Touring", types: [
                VehicleTypeDetail(name: "adventure", displayName: "Adventure Touring"),
                VehicleTypeDetail(name: "cruiser", displayName: "Cruiser Touring"),
                VehicleTypeDetail(name: "luxury", displayName: "Luxury Touring")
            ]),
            VehicleSubcategory(name: "offroad", displayName: "Off-Road", types: [
                VehicleTypeDetail(name: "enduro", displayName: "Enduro"),
                VehicleTypeDetail(name: "motocross", displayName: "Motocross"),
                VehicleTypeDetail(name: "dualsport", displayName: "Dual-Sport")
            ])
        ]
    )
    
    static let offroad = VehicleType(
        rawValue: "offroad",
        displayName: "Off-Road Vehicles",
        subcategories: [
            VehicleSubcategory(name: "atv", displayName: "ATV", types: [
                VehicleTypeDetail(name: "utility", displayName: "Utility ATV"),
                VehicleTypeDetail(name: "sport", displayName: "Sport ATV"),
                VehicleTypeDetail(name: "youth", displayName: "Youth ATV")
            ]),
            VehicleSubcategory(name: "utv", displayName: "UTV", types: [
                VehicleTypeDetail(name: "utility", displayName: "Utility UTV"),
                VehicleTypeDetail(name: "recreational", displayName: "Recreational UTV"),
                VehicleTypeDetail(name: "crew", displayName: "Crew UTV")
            ])
        ]
    )
    
    static let agricultural = VehicleType(
        rawValue: "agricultural",
        displayName: "Agricultural Equipment",
        subcategories: [
            VehicleSubcategory(name: "tractor", displayName: "Tractor", types: [
                VehicleTypeDetail(name: "compact", displayName: "Compact Tractor"),
                VehicleTypeDetail(name: "utility", displayName: "Utility Tractor"),
                VehicleTypeDetail(name: "row_crop", displayName: "Row Crop Tractor"),
                VehicleTypeDetail(name: "specialty", displayName: "Specialty Tractor"),
                VehicleTypeDetail(name: "track", displayName: "Track Tractor"),
                VehicleTypeDetail(name: "antique", displayName: "Antique Tractor")
            ]),
            VehicleSubcategory(name: "harvester", displayName: "Harvester", types: [
                VehicleTypeDetail(name: "combine", displayName: "Combine Harvester"),
                VehicleTypeDetail(name: "forage", displayName: "Forage Harvester"),
                VehicleTypeDetail(name: "cane", displayName: "Cane Harvester"),
                VehicleTypeDetail(name: "windrower", displayName: "Windrower")
            ]),
            VehicleSubcategory(name: "sprayer", displayName: "Sprayer", types: [
                VehicleTypeDetail(name: "self_propelled", displayName: "Self-propelled"),
                VehicleTypeDetail(name: "pull_behind", displayName: "Pull-behind")
            ]),
            VehicleSubcategory(name: "implement", displayName: "Implement", types: [
                VehicleTypeDetail(name: "plow", displayName: "Plow"),
                VehicleTypeDetail(name: "seeder", displayName: "Seeder"),
                VehicleTypeDetail(name: "baler", displayName: "Baler"),
                VehicleTypeDetail(name: "mower", displayName: "Mower"),
                VehicleTypeDetail(name: "other", displayName: "Other")
            ])
        ]
    )
    
    static let construction = VehicleType(
        rawValue: "construction",
        displayName: "Construction Equipment",
        subcategories: [
            VehicleSubcategory(name: "excavator", displayName: "Excavator", types: [
                VehicleTypeDetail(name: "mini", displayName: "Mini Excavator"),
                VehicleTypeDetail(name: "standard", displayName: "Standard Excavator"),
                VehicleTypeDetail(name: "long_reach", displayName: "Long-Reach Excavator")
            ]),
            VehicleSubcategory(name: "loader", displayName: "Loader", types: [
                VehicleTypeDetail(name: "skid_steer", displayName: "Skid Steer Loader"),
                VehicleTypeDetail(name: "backhoe", displayName: "Backhoe Loader"),
                VehicleTypeDetail(name: "wheel", displayName: "Wheel Loader"),
                VehicleTypeDetail(name: "track", displayName: "Track Loader")
            ]),
            VehicleSubcategory(name: "dozer", displayName: "Dozer", types: [
                VehicleTypeDetail(name: "crawler", displayName: "Crawler Dozer"),
                VehicleTypeDetail(name: "mini", displayName: "Mini Dozer")
            ]),
            VehicleSubcategory(name: "grader", displayName: "Grader", types: [
                VehicleTypeDetail(name: "motor_grader", displayName: "Motor Grader")
            ]),
            VehicleSubcategory(name: "compactor", displayName: "Compactor", types: [
                VehicleTypeDetail(name: "roller", displayName: "Roller Compactor")
            ])
        ]
    )
    
    static let recreational = VehicleType(
        rawValue: "recreational",
        displayName: "Recreational Vehicles (RVs)",
        subcategories: [
            VehicleSubcategory(name: "motorhome", displayName: "Motorhome", types: [
                VehicleTypeDetail(name: "class_a", displayName: "Class A"),
                VehicleTypeDetail(name: "class_b", displayName: "Class B"),
                VehicleTypeDetail(name: "class_c", displayName: "Class C")
            ]),
            VehicleSubcategory(name: "travel_trailer", displayName: "Travel Trailer", types: [
                VehicleTypeDetail(name: "fifth_wheel", displayName: "Fifth-Wheel"),
                VehicleTypeDetail(name: "lightweight", displayName: "Lightweight"),
                VehicleTypeDetail(name: "toy_hauler", displayName: "Toy Hauler")
            ]),
            VehicleSubcategory(name: "camper", displayName: "Camper", types: [
                VehicleTypeDetail(name: "slide_in", displayName: "Slide-In Camper"),
                VehicleTypeDetail(name: "pop_up", displayName: "Pop-Up Camper")
            ])
        ]
    )
    
    static let watercraft = VehicleType(
        rawValue: "watercraft",
        displayName: "Boats and Watercraft",
        subcategories: [
            VehicleSubcategory(name: "boat", displayName: "Boat", types: [
                VehicleTypeDetail(name: "fishing", displayName: "Fishing Boat"),
                VehicleTypeDetail(name: "speed", displayName: "Speedboat"),
                VehicleTypeDetail(name: "cabin_cruiser", displayName: "Cabin Cruiser")
            ]),
            VehicleSubcategory(name: "jetski", displayName: "Jet Ski", types: [
                VehicleTypeDetail(name: "stand_up", displayName: "Stand-Up"),
                VehicleTypeDetail(name: "two_person", displayName: "Two Person"),
                VehicleTypeDetail(name: "three_person", displayName: "Three Person")
            ]),
            VehicleSubcategory(name: "pontoon", displayName: "Pontoon", types: [
                VehicleTypeDetail(name: "fishing", displayName: "Fishing Pontoon"),
                VehicleTypeDetail(name: "luxury", displayName: "Luxury Pontoon")
            ])
        ]
    )
    
    static let commercial = VehicleType(
        rawValue: "commercial",
        displayName: "Commercial Vehicles",
        subcategories: [
            VehicleSubcategory(name: "semi_truck", displayName: "Semi-Truck", types: [
                VehicleTypeDetail(name: "day_cab", displayName: "Day Cab"),
                VehicleTypeDetail(name: "sleeper", displayName: "Sleeper Cab")
            ]),
            VehicleSubcategory(name: "box_truck", displayName: "Box Truck", types: [
                VehicleTypeDetail(name: "refrigerated", displayName: "Refrigerated"),
                VehicleTypeDetail(name: "standard", displayName: "Standard")
            ]),
            VehicleSubcategory(name: "van", displayName: "Van", types: [
                VehicleTypeDetail(name: "step_van", displayName: "Step Van"),
                VehicleTypeDetail(name: "parcel", displayName: "Parcel Delivery Van")
            ])
        ]
    )
    
    static let industrial = VehicleType(
        rawValue: "industrial",
        displayName: "Industrial Equipment",
        subcategories: [
            VehicleSubcategory(name: "forklift", displayName: "Forklift", types: [
                VehicleTypeDetail(name: "electric", displayName: "Electric Forklift"),
                VehicleTypeDetail(name: "diesel", displayName: "Diesel Forklift")
            ]),
            VehicleSubcategory(name: "crane", displayName: "Crane", types: [
                VehicleTypeDetail(name: "mobile", displayName: "Mobile Crane"),
                VehicleTypeDetail(name: "tower", displayName: "Tower Crane")
            ]),
            VehicleSubcategory(name: "stationary", displayName: "Stationary Engine", types: [
                VehicleTypeDetail(name: "compressor", displayName: "Compressor"),
                VehicleTypeDetail(name: "pump", displayName: "Pump"),
                VehicleTypeDetail(name: "vacuum", displayName: "Vacuum")
            ])
        ]
    )
    
    static let smallEngine = VehicleType(
        rawValue: "smallengine",
        displayName: "Small Engine Equipment",
        subcategories: [
            VehicleSubcategory(name: "lawn_mower", displayName: "Lawn Mower", types: [
                VehicleTypeDetail(name: "push", displayName: "Push Mower"),
                VehicleTypeDetail(name: "riding", displayName: "Riding Mower"),
                VehicleTypeDetail(name: "zero_turn", displayName: "Zero-Turn Mower")
            ]),
            VehicleSubcategory(name: "snow_blower", displayName: "Snow Blower", types: [
                VehicleTypeDetail(name: "single_stage", displayName: "Single-Stage"),
                VehicleTypeDetail(name: "two_stage", displayName: "Two-Stage"),
                VehicleTypeDetail(name: "three_stage", displayName: "Three-Stage")
            ]),
            VehicleSubcategory(name: "generator", displayName: "Generator", types: [
                VehicleTypeDetail(name: "standby", displayName: "Standby Generator"),
                VehicleTypeDetail(name: "portable", displayName: "Portable Generator")
            ]),
            VehicleSubcategory(name: "chainsaw", displayName: "Chainsaw", types: [
                VehicleTypeDetail(name: "gas", displayName: "Gas Chainsaw"),
                VehicleTypeDetail(name: "electric", displayName: "Electric Chainsaw")
            ]),
            VehicleSubcategory(name: "garden", displayName: "Garden Equipment", types: [
                VehicleTypeDetail(name: "rototiller", displayName: "Rototiller"),
                VehicleTypeDetail(name: "trimmer", displayName: "Trimmer"),
                VehicleTypeDetail(name: "pruner", displayName: "Pruner"),
                VehicleTypeDetail(name: "blower", displayName: "Blower"),
                VehicleTypeDetail(name: "auger", displayName: "Auger"),
                VehicleTypeDetail(name: "cutter", displayName: "Cutter")
            ])
        ]
    )
    
    static let aircraft = VehicleType(
        rawValue: "aircraft",
        displayName: "Aircraft",
        subcategories: [
            VehicleSubcategory(name: "airplane", displayName: "Airplane", types: [
                VehicleTypeDetail(name: "single_engine", displayName: "Single-Engine"),
                VehicleTypeDetail(name: "multi_engine", displayName: "Multi-Engine"),
                VehicleTypeDetail(name: "jet", displayName: "Jet")
            ]),
            VehicleSubcategory(name: "helicopter", displayName: "Helicopter", types: [
                VehicleTypeDetail(name: "light_utility", displayName: "Light Utility"),
                VehicleTypeDetail(name: "heavy_lift", displayName: "Heavy-Lift")
            ])
        ]
    )
    
    static let other = VehicleType(
        rawValue: "other",
        displayName: "Other",
        subcategories: [
            VehicleSubcategory(name: "other", displayName: "Other", types: [
                VehicleTypeDetail(name: "other", displayName: "Other")
            ])
        ]
    )
    
    static let allTypes: [VehicleType] = [
        .automobiles, .motorcycles, .offroad, .agricultural,
        .construction, .recreational, .watercraft, .commercial,
        .industrial, .smallEngine, .aircraft, .other
    ]
    
    static func from(rawValue: String) -> VehicleType {
        allTypes.first { $0.rawValue == rawValue } ?? .automobiles
    }
}

struct FuelType: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let gasoline = FuelType(rawValue: "gasoline", displayName: "Gasoline")
    static let diesel = FuelType(rawValue: "diesel", displayName: "Diesel")
    static let electric = FuelType(rawValue: "electric", displayName: "Electric")
    static let hybrid = FuelType(rawValue: "hybrid", displayName: "Hybrid")
    static let pluginHybrid = FuelType(rawValue: "pluginhybrid", displayName: "Plug-in Hybrid")
    static let naturalGas = FuelType(rawValue: "naturalgas", displayName: "Natural Gas")
    static let propane = FuelType(rawValue: "propane", displayName: "Propane")
    static let hydrogen = FuelType(rawValue: "hydrogen", displayName: "Hydrogen")
    static let other = FuelType(rawValue: "other", displayName: "Other")
    
    static let allTypes: [FuelType] = [
        .gasoline, .diesel, .electric, .hybrid, .pluginHybrid,
        .naturalGas, .propane, .hydrogen, .other
    ]
    
    static func from(rawValue: String) -> FuelType {
        allTypes.first { $0.rawValue == rawValue } ?? .gasoline
    }
}

struct BodyStyle: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let sedan = BodyStyle(rawValue: "sedan", displayName: "Sedan")
    static let coupe = BodyStyle(rawValue: "coupe", displayName: "Coupe")
    static let hatchback = BodyStyle(rawValue: "hatchback", displayName: "Hatchback")
    static let wagon = BodyStyle(rawValue: "wagon", displayName: "Wagon")
    static let suv = BodyStyle(rawValue: "suv", displayName: "SUV")
    static let truck = BodyStyle(rawValue: "truck", displayName: "Truck")
    static let van = BodyStyle(rawValue: "van", displayName: "Van")
    static let convertible = BodyStyle(rawValue: "convertible", displayName: "Convertible")
    static let other = BodyStyle(rawValue: "other", displayName: "Other")
    
    static let allTypes: [BodyStyle] = [
        .sedan, .coupe, .hatchback, .wagon, .suv,
        .truck, .van, .convertible, .other
    ]
    
    static func from(rawValue: String) -> BodyStyle {
        allTypes.first { $0.rawValue == rawValue } ?? .sedan
    }
}

struct EventType: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let observation = EventType(rawValue: "observation", displayName: "Observation")
    static let repair = EventType(rawValue: "repair", displayName: "Repair")
    static let service = EventType(rawValue: "service", displayName: "Service")
    
    static let allTypes: [EventType] = [.observation, .repair, .service]
    
    static func from(rawValue: String) -> EventType {
        allTypes.first { $0.rawValue == rawValue } ?? .observation
    }
}

struct OwnershipEventType: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let purchased = OwnershipEventType(rawValue: "purchased", displayName: "Purchased")
    static let sold = OwnershipEventType(rawValue: "sold", displayName: "Sold")
    static let registered = OwnershipEventType(rawValue: "registered", displayName: "Registered")
    static let insured = OwnershipEventType(rawValue: "insured", displayName: "Insured")
    static let leased = OwnershipEventType(rawValue: "leased", displayName: "Leased")
    static let gifted = OwnershipEventType(rawValue: "gifted", displayName: "Gifted")
    static let scrapped = OwnershipEventType(rawValue: "scrapped", displayName: "Scrapped/Retired")
    static let loaned = OwnershipEventType(rawValue: "loaned", displayName: "Loaned")
    static let transferred = OwnershipEventType(rawValue: "transferred", displayName: "Transferred")
    static let exported = OwnershipEventType(rawValue: "exported", displayName: "Exported")
    
    static let allTypes: [OwnershipEventType] = [
        .purchased, .sold, .registered, .insured, .leased,
        .gifted, .scrapped, .loaned, .transferred, .exported
    ]
    
    static func from(rawValue: String) -> OwnershipEventType {
        allTypes.first { $0.rawValue == rawValue } ?? .purchased
    }
}

struct EngineType: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let i3 = EngineType(rawValue: "i3", displayName: "Inline 3-Cylinder")
    static let i4 = EngineType(rawValue: "i4", displayName: "Inline 4-Cylinder")
    static let i5 = EngineType(rawValue: "i5", displayName: "Inline 5-Cylinder")
    static let i6 = EngineType(rawValue: "i6", displayName: "Inline 6-Cylinder")
    static let i8 = EngineType(rawValue: "i8", displayName: "Inline 8-Cylinder")
    static let v4 = EngineType(rawValue: "v4", displayName: "V4")
    static let v6 = EngineType(rawValue: "v6", displayName: "V6")
    static let v8 = EngineType(rawValue: "v8", displayName: "V8")
    static let v10 = EngineType(rawValue: "v10", displayName: "V10")
    static let v12 = EngineType(rawValue: "v12", displayName: "V12")
    static let v16 = EngineType(rawValue: "v16", displayName: "V16")
    static let w8 = EngineType(rawValue: "w8", displayName: "W8")
    static let w12 = EngineType(rawValue: "w12", displayName: "W12")
    static let w16 = EngineType(rawValue: "w16", displayName: "W16")
    static let flat4 = EngineType(rawValue: "flat4", displayName: "Flat 4-Cylinder")
    static let flat6 = EngineType(rawValue: "flat6", displayName: "Flat 6-Cylinder")
    static let flat8 = EngineType(rawValue: "flat8", displayName: "Flat 8-Cylinder")
    static let flat12 = EngineType(rawValue: "flat12", displayName: "Flat 12-Cylinder")
    static let electric = EngineType(rawValue: "electric", displayName: "Electric Motor")
    static let hybrid = EngineType(rawValue: "hybrid", displayName: "Hybrid")
    static let rotary = EngineType(rawValue: "rotary", displayName: "Rotary")
    static let diesel = EngineType(rawValue: "diesel", displayName: "Diesel")
    static let twinRotary = EngineType(rawValue: "twinrotary", displayName: "Twin Rotary")
    static let tripleRotary = EngineType(rawValue: "triplerotary", displayName: "Triple Rotary")
    static let radial = EngineType(rawValue: "radial", displayName: "Radial")
    static let turboprop = EngineType(rawValue: "turboprop", displayName: "Turboprop")
    static let turbojet = EngineType(rawValue: "turbojet", displayName: "Turbojet")
    static let turbofan = EngineType(rawValue: "turbofan", displayName: "Turbofan")
    static let turboshaft = EngineType(rawValue: "turboshaft", displayName: "Turboshaft")
    
    // Small Engines
    static let singleCylinder = EngineType(rawValue: "single_cylinder", displayName: "Single Cylinder")
    static let twinCylinder = EngineType(rawValue: "twin_cylinder", displayName: "Twin Cylinder")
    static let twoCycle = EngineType(rawValue: "two_cycle", displayName: "2-Cycle")
    static let fourCycle = EngineType(rawValue: "four_cycle", displayName: "4-Cycle")
    
    // Marine Engines
    static let outboard = EngineType(rawValue: "outboard", displayName: "Outboard Motor")
    static let inboard = EngineType(rawValue: "inboard", displayName: "Inboard Motor")
    static let sterndrive = EngineType(rawValue: "sterndrive", displayName: "Sterndrive (I/O)")
    static let jetDrive = EngineType(rawValue: "jet_drive", displayName: "Jet Drive")
    static let marineDiesel = EngineType(rawValue: "marine_diesel", displayName: "Marine Diesel")
    
    // Personal Watercraft
    static let pwcTwoCycle = EngineType(rawValue: "pwc_two_cycle", displayName: "PWC 2-Cycle")
    static let pwcFourCycle = EngineType(rawValue: "pwc_four_cycle", displayName: "PWC 4-Cycle")
    static let pwcSupercharged = EngineType(rawValue: "pwc_supercharged", displayName: "PWC Supercharged")
    
    static let other = EngineType(rawValue: "other", displayName: "Other")
    
    static let allTypes: [EngineType] = [
        // Automotive Inline
        .i3, .i4, .i5, .i6, .i8,
        // Automotive V
        .v4, .v6, .v8, .v10, .v12, .v16,
        // Automotive W
        .w8, .w12, .w16,
        // Automotive Flat
        .flat4, .flat6, .flat8, .flat12,
        // Alternative
        .electric, .hybrid,
        // Rotary
        .rotary, .twinRotary, .tripleRotary,
        // Diesel
        .diesel, .marineDiesel,
        // Small Engines
        .singleCylinder, .twinCylinder,
        .twoCycle, .fourCycle,
        // Marine
        .outboard, .inboard, .sterndrive, .jetDrive,
        // Personal Watercraft
        .pwcTwoCycle, .pwcFourCycle, .pwcSupercharged,
        // Aircraft
        .radial,
        .turboprop, .turbojet, .turbofan, .turboshaft,
        // Other
        .other
    ]
    
    static func from(rawValue: String) -> EngineType {
        allTypes.first { $0.rawValue == rawValue } ?? .other
    }
}

struct DriveType: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let twoWD = DriveType(rawValue: "2wd", displayName: "2WD")
    static let fourWD = DriveType(rawValue: "4wd", displayName: "4WD")
    static let awd = DriveType(rawValue: "awd", displayName: "AWD")
    static let rwd = DriveType(rawValue: "rwd", displayName: "RWD")
    static let fwd = DriveType(rawValue: "fwd", displayName: "FWD")
    static let other = DriveType(rawValue: "other", displayName: "Other")
    
    static let allTypes: [DriveType] = [
        .twoWD, .fourWD, .awd, .rwd, .fwd, .other
    ]
    
    static func from(rawValue: String) -> DriveType {
        allTypes.first { $0.rawValue == rawValue } ?? .other
    }
}

struct TransmissionType: Hashable {
    let rawValue: String
    let displayName: String
    
    private init(rawValue: String, displayName: String) {
        self.rawValue = rawValue
        self.displayName = displayName
    }
    
    static let automatic = TransmissionType(rawValue: "automatic", displayName: "Automatic")
    static let manual = TransmissionType(rawValue: "manual", displayName: "Manual")
    static let cvt = TransmissionType(rawValue: "cvt", displayName: "CVT")
    static let dct = TransmissionType(rawValue: "dct", displayName: "Dual-Clutch")
    static let amt = TransmissionType(rawValue: "amt", displayName: "Automated Manual")
    static let electric = TransmissionType(rawValue: "electric", displayName: "Electric")
    static let other = TransmissionType(rawValue: "other", displayName: "Other")
    
    static let allTypes: [TransmissionType] = [
        .automatic, .manual, .cvt, .dct, .amt, .electric, .other
    ]
    
    static func from(rawValue: String) -> TransmissionType {
        allTypes.first { $0.rawValue == rawValue } ?? .other
    }
}

enum VehicleSortOption: String, CaseIterable {
    case none = "none"
    case year = "year"
    case make = "make"
    case lastUpdated = "lastUpdated"
    case category = "category"
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .year:
            return "Year"
        case .make:
            return "Make"
        case .lastUpdated:
            return "Last Updated"
        case .category:
            return "Category"
        }
    }
}

enum VehicleGroupOption: String, CaseIterable {
    case none = "none"
    case category = "category"
    case make = "make"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .category:
            return "Category"
        case .make:
            return "Make"
        case .year:
            return "Year"
        }
    }
}

// MARK: - Models
@Model
final class Vehicle {
    // MARK: - Properties
    var id: String = UUID().uuidString
    
    // Vehicle Information
    var make: String = ""
    var model: String = ""
    var year: Int = Calendar.current.component(.year, from: Date())
    var color: String = "Black"
    var nickname: String?
    var icon: String = ""  // Default to no icon
    var isPinned: Bool = false
    
    // Categorization
    var categoryRawValue: String = VehicleType.automobiles.rawValue
    var subcategoryName: String?
    var typeName: String?
    
    // Details
    var trimLevel: String?
    var vin: String?
    var serialNumber: String?
    var fuelTypeRawValue: String = FuelType.gasoline.rawValue
    var engineTypeRawValue: String = EngineType.v8.rawValue
    var driveTypeRawValue: String = DriveType.twoWD.rawValue
    var transmissionTypeRawValue: String = TransmissionType.automatic.rawValue
    var notes: String?
    
    // System
    var addedDate: Date = Date()
    
    @Relationship(deleteRule: .cascade) var events: [Event]?
    @Relationship(deleteRule: .cascade) var ownershipRecords: [OwnershipRecord]?
    @Relationship(deleteRule: .cascade) var attachments: [Attachment]?
    
    // MARK: - Computed Properties
    var category: VehicleType {
        get { VehicleType.from(rawValue: categoryRawValue) }
        set { categoryRawValue = newValue.rawValue }
    }
    
    var subcategory: VehicleSubcategory? {
        get {
            guard let subcategoryName = subcategoryName else { return nil }
            return category.subcategories.first { $0.name == subcategoryName }
        }
        set { subcategoryName = newValue?.name }
    }
    
    var vehicleType: VehicleTypeDetail? {
        get {
            guard let subcategory = subcategory,
                  let typeName = typeName else { return nil }
            return subcategory.types.first { $0.name == typeName }
        }
        set { typeName = newValue?.name }
    }
    
    var fuelType: FuelType {
        get { FuelType.from(rawValue: fuelTypeRawValue) }
        set { fuelTypeRawValue = newValue.rawValue }
    }
    
    var engineType: EngineType {
        get { EngineType.from(rawValue: engineTypeRawValue) }
        set { engineTypeRawValue = newValue.rawValue }
    }
    
    var driveType: DriveType {
        get { DriveType.from(rawValue: driveTypeRawValue) }
        set { driveTypeRawValue = newValue.rawValue }
    }
    
    var transmissionType: TransmissionType {
        get { TransmissionType.from(rawValue: transmissionTypeRawValue) }
        set { transmissionTypeRawValue = newValue.rawValue }
    }
    
    var displayName: String {
        if let nickname = nickname {
            return "\(year) \(make) \(model) (\(nickname))"
        }
        return "\(year) \(make) \(model)"
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        make: String,
        model: String,
        year: Int,
        color: String = "Black",
        nickname: String? = nil,
        icon: String = "",
        isPinned: Bool = false,
        category: VehicleType,
        subcategory: VehicleSubcategory? = nil,
        vehicleType: VehicleTypeDetail? = nil,
        trimLevel: String? = nil,
        vin: String? = nil,
        serialNumber: String? = nil,
        fuelType: FuelType,
        engineType: EngineType,
        driveType: DriveType,
        transmission: TransmissionType,
        notes: String? = nil
    ) {
        self.id = id
        self.make = make.trimmingCharacters(in: .whitespaces)
        self.model = model.trimmingCharacters(in: .whitespaces)
        self.year = year
        self.color = color
        self.nickname = nickname
        self.icon = icon
        self.isPinned = isPinned
        self.categoryRawValue = category.rawValue
        self.subcategoryName = subcategory?.name
        self.typeName = vehicleType?.name
        self.trimLevel = trimLevel
        self.vin = vin
        self.serialNumber = serialNumber
        self.fuelTypeRawValue = fuelType.rawValue
        self.engineTypeRawValue = engineType.rawValue
        self.driveTypeRawValue = driveType.rawValue
        self.transmissionTypeRawValue = transmission.rawValue
        self.notes = notes
        self.events = []
        self.ownershipRecords = []
        self.addedDate = Date()
    }
    
    // MARK: - Methods
    func addEvent(_ event: Event) {
        if events == nil { events = [] }
        events?.append(event)
        event.vehicle = self
    }
    
    func addOwnershipRecord(_ record: OwnershipRecord) {
        if ownershipRecords == nil { ownershipRecords = [] }
        ownershipRecords?.append(record)
        record.vehicle = self
    }
    
    func updateMakeAndModel(make: String, model: String) {
        self.make = make.trimmingCharacters(in: .whitespaces)
        self.model = model.trimmingCharacters(in: .whitespaces)
    }
    
    func calculateMaintenanceCosts(from: Date? = nil, to: Date? = nil) -> Decimal {
        guard let events = events else { return 0 }
        
        // Filter events by type
        let maintenanceEvents = events.filter { event in
            event.category == .repair || event.category == .maintenance
        }
        
        // Filter by date range
        let dateFilteredEvents = maintenanceEvents.filter { event in
            if let fromDate = from, event.date < fromDate { return false }
            if let toDate = to, event.date > toDate { return false }
            return true
        }
        
        // Sum up costs
        let costs = dateFilteredEvents.compactMap { $0.cost }
        return costs.reduce(0, +)
    }
    
    static let commonColors = [
        "White",
        "Black",
        "Gray",
        "Red",
        "Blue",
        "Green",
        "Brown",
        "Orange",
        "Yellow",
        "Purple",
        "Burgundy",
        "Navy",
    ]
}

@Model
final class Event {
    var id: String = UUID().uuidString
    var categoryId: String = EventCategory.observation.id
    var subcategoryId: String = EventCategory.observation.subcategories[0].id
    var date: Date = Date()
    var details: String?
    var mileage: Decimal?
    var distanceUnit: String = DistanceUnit.miles.rawValue
    var hours: Decimal?
    var cost: Decimal?
    var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    
    @Relationship var vehicle: Vehicle?
    
    var category: EventCategory {
        get { EventCategory.allCategories.first { $0.id == categoryId } ?? EventCategory.observation }
        set { categoryId = newValue.id }
    }
    
    var subcategory: EventSubcategory {
        get { category.subcategories.first { $0.id == subcategoryId } ?? category.subcategories[0] }
        set { subcategoryId = newValue.id }
    }
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var formattedMileage: String? {
        guard let mileage = mileage else { return nil }
        let unit = DistanceUnit(rawValue: distanceUnit) ?? .miles
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return (formatter.string(from: NSDecimalNumber(decimal: mileage)) ?? "\(mileage)") + " \(unit.rawValue)"
    }
    
    var formattedHours: String? {
        guard let hours = hours else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return (formatter.string(from: NSDecimalNumber(decimal: hours)) ?? "\(hours)") + " hrs"
    }
    
    var formattedCost: String? {
        guard let cost = cost else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSDecimalNumber(decimal: cost))
    }
    
    init(
        id: String = UUID().uuidString,
        category: EventCategory = .observation,
        subcategory: EventSubcategory? = nil,
        date: Date = Date(),
        details: String? = nil,
        mileage: Decimal? = nil,
        distanceUnit: DistanceUnit = .miles,
        hours: Decimal? = nil,
        cost: Decimal? = nil,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    ) {
        self.id = id
        self.categoryId = category.id
        self.subcategoryId = subcategory?.id ?? category.subcategories[0].id
        self.date = date
        self.details = details
        self.mileage = mileage
        self.distanceUnit = distanceUnit.rawValue
        self.hours = hours
        self.cost = cost
        self.currencyCode = currencyCode
    }
}

@Model
final class OwnershipRecord {
    var id: String = UUID().uuidString
    var typeRawValue: String = OwnershipEventType.purchased.rawValue
    var date: Date = Date()
    var details: String?
    var mileage: Decimal?
    var distanceUnit: String = DistanceUnit.miles.rawValue
    var hours: Decimal?
    var cost: Decimal?
    var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    
    @Relationship var vehicle: Vehicle?
    
    var type: OwnershipEventType {
        get { OwnershipEventType.from(rawValue: typeRawValue) }
        set { typeRawValue = newValue.rawValue }
    }
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var formattedMileage: String? {
        guard let mileage = mileage else { return nil }
        let unit = DistanceUnit(rawValue: distanceUnit) ?? .miles
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return (formatter.string(from: NSDecimalNumber(decimal: mileage)) ?? "\(mileage)") + " \(unit.rawValue)"
    }
    
    var formattedHours: String? {
        guard let hours = hours else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return (formatter.string(from: NSDecimalNumber(decimal: hours)) ?? "\(hours)") + " hrs"
    }
    
    var formattedCost: String? {
        guard let cost = cost else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSDecimalNumber(decimal: cost))
    }
    
    init(
        id: String = UUID().uuidString,
        type: OwnershipEventType,
        date: Date = Date(),
        details: String? = nil,
        mileage: Decimal? = nil,
        distanceUnit: DistanceUnit = .miles,
        hours: Decimal? = nil,
        cost: Decimal? = nil,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.date = date
        self.details = details
        self.mileage = mileage
        self.distanceUnit = distanceUnit.rawValue
        self.hours = hours
        self.cost = cost
        self.currencyCode = currencyCode
    }
}

@Model
final class Attachment {
    var id: String = UUID().uuidString
    var fileName: String = ""
    var fileExtension: String = ""
    var mimeType: String = ""
    var data: Data = Data()
    var addedDate: Date = Date()
    var vehicle: Vehicle?
    
    init(id: String = UUID().uuidString,
         fileName: String = "",
         fileExtension: String = "",
         mimeType: String = "",
         data: Data = Data(),
         addedDate: Date = Date(),
         vehicle: Vehicle? = nil) {
        self.id = id
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.data = data
        self.addedDate = addedDate
        self.vehicle = vehicle
    }
    
    var displayName: String {
        fileName + (fileExtension.isEmpty ? "" : "." + fileExtension)
    }
    
    var isImage: Bool {
        ["jpg", "jpeg", "png", "heic", "heif"].contains(fileExtension.lowercased())
    }
    
    var isPDF: Bool {
        fileExtension.lowercased() == "pdf"
    }
    
    var isAudio: Bool {
        fileExtension.lowercased() == "m4a"
    }
} 
