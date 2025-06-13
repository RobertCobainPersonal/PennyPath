//
//  Category.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI // Import SwiftUI to use the Color type

/// Represents a user-defined spending category or sub-category.
struct Category: Codable, Identifiable, Hashable {
    
    @DocumentID var id: String?
    
    var name: String
    
    /// The name of an SF Symbol to be used as the icon.
    var iconName: String
    
    /// The hex string representation of the category's color (e.g., "#FFFFFF").
    var colorHex: String
    
    /// If this is a sub-category, this field will contain the ID of its parent category.
    /// If this is a top-level category, this will be nil.
    var parentCategoryId: String?
    
    /// A computed property to easily convert the hex string to a SwiftUI Color.
    var color: Color {
        Color(hex: colorHex) ?? .black
    }
}

// An extension on Color to allow initialization from a hex string.
// This is a helpful utility for working with colors from a database.
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
