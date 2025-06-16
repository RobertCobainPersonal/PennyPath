//
//  FloatingActionButton.swift
//  PennyPath
//
//  Created by Robert Cobain on 16/06/2025.
//

import SwiftUI

struct FloatingActionButton: View {
    @Binding var isExpanded: Bool
    @State private var showingAddTransaction = false
    @State private var showingAddAccount = false
    @State private var showingAddBudget = false
    
    private let buttonSize: CGFloat = 56
    private let smallButtonSize: CGFloat = 44
    
    var body: some View {
        ZStack {
            // Background overlay when expanded
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                    }
            }
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Quick action buttons (shown when expanded)
                        if isExpanded {
                            VStack(spacing: 12) {
                                quickActionButton(
                                    title: "Add Budget",
                                    icon: "chart.bar.fill",
                                    color: .purple
                                ) {
                                    showingAddBudget = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isExpanded = false
                                    }
                                }
                                
                                quickActionButton(
                                    title: "Add Account",
                                    icon: "plus.circle.fill",
                                    color: .green
                                ) {
                                    showingAddAccount = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isExpanded = false
                                    }
                                }
                                
                                quickActionButton(
                                    title: "Add Transaction",
                                    icon: "dollarsign.circle.fill",
                                    color: .blue
                                ) {
                                    showingAddTransaction = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isExpanded = false
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // Main FAB button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "xmark" : "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(
                                    Circle()
                                        .fill(Color.blue.gradient)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                                .rotationEffect(.degrees(isExpanded ? 135 : 0))
                        }
                        .scaleEffect(isExpanded ? 1.1 : 1.0)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120) // Increased padding to clear tab bar and content
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionPlaceholderView()
        }
        .sheet(isPresented: $showingAddAccount) {
            AddAccountPlaceholderView()
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetPlaceholderView()
        }
    }
    
    // MARK: - Helper Views
    
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: smallButtonSize, height: smallButtonSize)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views for Sheets

struct AddTransactionPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Add Transaction")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This will be the transaction creation form")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddAccountPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Add Account")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This will be the account creation form")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddBudgetPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Add Budget")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This will be the budget creation form")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            FloatingActionButton(isExpanded: .constant(false))
        }
    }
}
