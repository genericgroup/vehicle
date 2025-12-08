import Foundation

struct Manufacturer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    
    static let commonManufacturers = [
        // Cars & Light Vehicles
        "Acura", "Alfa Romeo", "Aston Martin", "Audi", "Bentley", "BMW", "Bugatti",
        "Buick", "Cadillac", "Chevrolet", "Chrysler", "Citroën", "Dodge", "Ferrari",
        "Fiat", "Ford", "Genesis", "GMC", "Honda", "Hyundai", "Infiniti", "Jaguar",
        "Jeep", "Kia", "Lamborghini", "Land Rover", "Lexus", "Lincoln", "Lotus",
        "Maserati", "Mazda", "McLaren", "Mercedes-Benz", "MINI", "Mitsubishi",
        "Nissan", "Pagani", "Peugeot", "Porsche", "Ram", "Renault", "Rolls-Royce",
        "Saab", "Subaru", "Suzuki", "Tesla", "Toyota", "Volkswagen", "Volvo",
        
        // Motorcycles & Powersports
        "Aprilia", "Arctic Cat", "BMW Motorrad", "Can-Am", "Ducati", "Harley-Davidson",
        "Honda Motorcycles", "Indian Motorcycle", "Kawasaki", "KTM", "Moto Guzzi",
        "MV Agusta", "Polaris", "Royal Enfield", "Segway Powersports", "Triumph",
        "Yamaha", "Zero Motorcycles",
        
        // Commercial & Heavy Vehicles
        "Blue Bird", "DAF", "Freightliner", "Gehl", "Grove", "Hino", "International",
        "Isuzu", "Kenworth", "Mack", "MAN", "Manitou", "Peterbilt", "Scania",
        "Shantui", "Takeuchi", "Vermeer", "Volvo Trucks", "Western Star",
        
        // Agricultural & Farm Equipment
        "AGCO", "Alamo", "Bad Boy", "Bush Hog", "Case IH", "Challenger", "Claas",
        "Deutz-Fahr", "Fendt", "Gravely", "Great Plains", "Hustler", "Jacobsen",
        "John Deere", "Kioti", "Kubota", "Land Pride", "Mahindra", "Massey Ferguson",
        "New Holland", "Scag", "Shibaura", "TYM Tractors", "Valtra", "Versatile",
        "Walker", "Yanmar",
        
        // Construction & Heavy Equipment
        "Bobcat", "Caterpillar", "Doosan", "Hitachi", "Hyundai Construction Equipment",
        "JCB", "Komatsu", "Liebherr", "Terex", "Volvo Construction Equipment",
        
        // Recreational & Outdoor Power Equipment
        "Airstream", "Ariens", "Chaparral", "Coachmen", "Craftsman", "Cub Cadet",
        "Echo", "Forest River", "Four Winns", "Honda Power Equipment", "Husqvarna",
        "Jayco", "Keystone", "Malibu Boats", "Snapper", "Stihl", "Toro", "Tracker Boats",
        "Winnebago",
        
        // Aircraft & Helicopters
        "Airbus Helicopters", "Beechcraft", "Bell Helicopter", "Bombardier", "Cessna",
        "Cirrus", "Dassault", "Diamond Aircraft", "Embraer", "Gulfstream", "Hawker",
        "Mooney", "Piper", "Robinson Helicopter", "Sikorsky",
        
        // Watercraft & Marine
        "Bayliner", "Boston Whaler", "Brunswick", "Chaparral", "Chris-Craft",
        "Four Winns", "Grady-White", "Kawasaki Jet Ski", "Malibu Boats",
        "MasterCraft", "Mercury Marine", "Sea-Doo", "Tracker Boats", "Yamaha Marine"
    ].sorted()
    
    static func suggestions(for searchText: String) -> [String] {
        if searchText.isEmpty {
            return []
        }
        return commonManufacturers.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
} 