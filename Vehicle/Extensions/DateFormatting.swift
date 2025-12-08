import Foundation

extension Date {
    var standardFormatted: String {
        self.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.defaultDigits))
    }
    
    var standardFormattedLong: String {
        self.formatted(.dateTime.month(.wide).day(.defaultDigits).year(.defaultDigits))
    }
    
    var standardFormattedNumeric: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: self)
    }
} 