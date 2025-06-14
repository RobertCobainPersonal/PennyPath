//
//  CategoryRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//


//
//  CategoryRowView.swift
//  PennyPath
//
//  Created by Robert Cobain on 13/06/2025.
//

import SwiftUI

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.iconName)
                .font(.headline)
                .foregroundColor(category.color)
                .frame(width: 30, height: 30)
                .background(category.color.opacity(0.15))
                .cornerRadius(8)
            
            Text(category.name)
        }
    }
}

struct SubCategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.turn.down.right")
                .foregroundColor(.secondary)
            
            Image(systemName: category.iconName)
                .foregroundColor(category.color)

            Text(category.name)
        }
    }
}
