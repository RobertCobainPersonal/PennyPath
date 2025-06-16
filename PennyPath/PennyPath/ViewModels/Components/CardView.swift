//
//  CardView.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//


import SwiftUI

/// Reusable card container following Apple's Human Interface Guidelines
/// Provides consistent styling and shadows across the app
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview Provider
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CardView {
                VStack(alignment: .leading) {
                    Text("Sample Card")
                        .font(.headline)
                    Text("This is how our card component looks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            CardView {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Another card style")
                    Spacer()
                    Text("$1,234")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}