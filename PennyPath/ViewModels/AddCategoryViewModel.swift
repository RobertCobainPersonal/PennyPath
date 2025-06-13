//
//  AddCategoryViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//


//
//  AddCategoryViewModel.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import Foundation
import SwiftUI // Import SwiftUI to use Color

@MainActor
class AddCategoryViewModel: ObservableObject {
    
    @Published var name: String = ""
    @Published var iconName: String = "questionmark.circle" // A default icon
    @Published var color: Color = .blue
    @Published var parentCategoryId: String? = nil // nil means it's a top-level category

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func save() async throws {
        let newCategory = Category(
            name: name,
            iconName: iconName,
            colorHex: color.toHex() ?? "#000000",
            parentCategoryId: parentCategoryId
        )
        
        try await CategoryService.shared.saveCategory(newCategory)
    }
}

// A helper extension to convert SwiftUI Color to a Hex String for storing in Firestore.
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}