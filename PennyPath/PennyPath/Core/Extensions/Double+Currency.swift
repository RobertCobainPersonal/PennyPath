//
//  Double+Currency.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import Foundation

/// Currency formatting extensions for Double - UK focused
extension Double {
    
    /// Format as GBP currency with proper UK locale handling
    /// Example: 1234.56 -> "£1,234.56"
    var formattedAsCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.locale = Locale(identifier: "en_GB")
        return formatter.string(from: NSNumber(value: self)) ?? "£0.00"
    }
    
    /// Format as currency without pence for large numbers
    /// Example: 1234.56 -> "£1,235", 12.34 -> "£12.34"
    var formattedAsCurrencyCompact: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = abs(self) >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "£0"
    }
    
    /// Format as abbreviated currency for very large numbers
    /// Example: 1234567 -> "£1.2M", 1234 -> "£1.2K"
    var formattedAsCurrencyAbbreviated: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.locale = Locale(identifier: "en_GB")
        
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        
        switch absValue {
        case 1_000_000_000...:
            formatter.maximumFractionDigits = 1
            let billions = absValue / 1_000_000_000
            return "\(sign)\(formatter.string(from: NSNumber(value: billions)) ?? "£0")B"
        case 1_000_000...:
            formatter.maximumFractionDigits = 1
            let millions = absValue / 1_000_000
            return "\(sign)\(formatter.string(from: NSNumber(value: millions)) ?? "£0")M"
        case 1_000...:
            formatter.maximumFractionDigits = 1
            let thousands = absValue / 1_000
            return "\(sign)\(formatter.string(from: NSNumber(value: thousands)) ?? "£0")K"
        default:
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: self)) ?? "£0.00"
        }
    }
}
