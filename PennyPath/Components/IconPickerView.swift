//
//  IconPickerView.swift
//  PennyPath
//
//  Created by Robert Cobain on 12/06/2025.
//

import SwiftUI

struct IconPickerView: View {
    // This view receives a "binding" to the iconName property from its parent view.
    // When an icon is tapped here, it updates the property in the parent.
    @Binding var selectedIconName: String
    @Environment(\.dismiss) private var dismiss
    
    // A curated list of SF Symbols relevant to finance and categories.
    private let iconNames: [String] = [
        "cart.fill", "bag.fill", "car.fill", "fuelpump.fill", "airplane", "bus.fill",
        "tram.fill", "bicycle", "figure.walk", "house.fill", "bolt.fill", "gift.fill",
        "book.fill", "display", "gamecontroller.fill", "film.fill", "music.note",
        "fork.knife", "cup.and.saucer.fill", "pills.fill", "tshirt.fill", "dollarsign.circle.fill",
        "eurosign.circle.fill", "sterlingsign.circle.fill"
    ]
    
    // Define the grid layout: 5 columns, flexible size.
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 5)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(iconNames, id: \.self) { iconName in
                        Button(action: {
                            selectedIconName = iconName
                            dismiss()
                        }) {
                            Image(systemName: iconName)
                                .font(.title)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select an Icon")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
