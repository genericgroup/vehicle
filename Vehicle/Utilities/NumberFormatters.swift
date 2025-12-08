import Foundation

/// Shared, cached number formatters to avoid repeated instantiation
enum NumberFormatters {
    
    // MARK: - Decimal Formatter (with grouping)
    
    /// Formatter for displaying decimal numbers with grouping separators (e.g., 1,234.56)
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Formatter for displaying whole numbers with grouping separators (e.g., 1,234)
    static let wholeNumber: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Currency Formatters
    
    /// Cache of currency formatters by currency code
    private static var currencyFormatters: [String: NumberFormatter] = [:]
    private static let currencyFormatterLock = NSLock()
    
    /// Get a cached currency formatter for the specified currency code
    static func currency(code: String) -> NumberFormatter {
        currencyFormatterLock.lock()
        defer { currencyFormatterLock.unlock() }
        
        if let cached = currencyFormatters[code] {
            return cached
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        currencyFormatters[code] = formatter
        return formatter
    }
    
    // MARK: - Formatting Functions
    
    /// Format a decimal value with grouping separators
    static func formatDecimal(_ value: Decimal) -> String {
        decimal.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
    
    /// Format a decimal value with a unit suffix
    static func formatDecimalWithUnit(_ value: Decimal, unit: String) -> String {
        "\(formatDecimal(value)) \(unit)"
    }
    
    /// Format mileage with appropriate unit
    static func formatMileage(_ value: Decimal, unit: DistanceUnit) -> String {
        formatDecimalWithUnit(value, unit: unit.shortLabel)
    }
    
    /// Format hours
    static func formatHours(_ value: Decimal) -> String {
        formatDecimalWithUnit(value, unit: "hrs")
    }
    
    /// Format currency
    static func formatCurrency(_ value: Decimal, currencyCode: String) -> String {
        currency(code: currencyCode).string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
    
    /// Format a decimal for display in text fields (no grouping, minimal decimals)
    static func formatForInput(_ value: Decimal?) -> String {
        guard let value = value else { return "" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
        
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
}
