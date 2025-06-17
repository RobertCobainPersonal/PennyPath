//
//  ContextualFAB.swift
//  PennyPath
//
//  Created by Robert Cobain on 17/06/2025.
//


import SwiftUI

/// Contextual Floating Action Button that adapts based on current screen
struct ContextualFAB: View {
    let context: FABContext
    @Binding var isExpanded: Bool
    
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
                        // Context-specific action buttons (shown when expanded)
                        if isExpanded {
                            VStack(spacing: 12) {
                                ForEach(contextActions.reversed(), id: \.id) { action in
                                    contextualActionButton(action: action)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        // Main FAB button
                        Button(action: {
                            if contextActions.count > 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isExpanded.toggle()
                                }
                            } else {
                                // If only one action, execute it directly
                                contextActions.first?.action()
                            }
                        }) {
                            Image(systemName: isExpanded ? "xmark" : primaryAction.icon)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: buttonSize, height: buttonSize)
                                .background(
                                    Circle()
                                        .fill(primaryAction.color.gradient)
                                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                                .rotationEffect(.degrees(isExpanded ? 135 : 0))
                        }
                        .scaleEffect(isExpanded ? 1.1 : 1.0)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120) // Above tab bar
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
    }
    
    // MARK: - Context-Specific Actions
    
    private var contextActions: [FABAction] {
        switch context {
        case .dashboard:
            return [
                FABAction(
                    id: "add-transaction",
                    title: "Add Transaction",
                    icon: "dollarsign.circle.fill",
                    color: .blue,
                    action: {
                        print("Add transaction from dashboard")
                        isExpanded = false
                    }
                ),
                FABAction(
                    id: "add-account",
                    title: "Add Account",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: {
                        print("Add account from dashboard")
                        isExpanded = false
                    }
                ),
                FABAction(
                    id: "add-budget",
                    title: "Add Budget",
                    icon: "chart.bar.fill",
                    color: .purple,
                    action: {
                        print("Add budget from dashboard")
                        isExpanded = false
                    }
                )
            ]
        
        case .accountsList:
            return [
                FABAction(
                    id: "add-transaction",
                    title: "Add Transaction",
                    icon: "dollarsign.circle.fill",
                    color: .blue,
                    action: {
                        print("Add transaction from accounts list")
                        isExpanded = false
                    }
                ),
                FABAction(
                    id: "add-account",
                    title: "Add Account",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: {
                        print("Add account from accounts list")
                        isExpanded = false
                    }
                )
            ]
        
        case .accountDetail(let account):
            return [
                FABAction(
                    id: "add-transaction",
                    title: "Add Transaction",
                    icon: "plus",
                    color: .blue,
                    action: {
                        print("Add transaction to \(account.name)")
                        isExpanded = false
                    }
                ),
                FABAction(
                    id: "transfer",
                    title: "Transfer Money",
                    icon: "arrow.left.arrow.right",
                    color: .orange,
                    action: {
                        print("Transfer from \(account.name)")
                        isExpanded = false
                    }
                )
            ]
        
        case .transactions:
            return [
                FABAction(
                    id: "add-transaction",
                    title: "Add Transaction",
                    icon: "plus",
                    color: .blue,
                    action: {
                        print("Add transaction from transactions list")
                        isExpanded = false
                    }
                )
            ]
        }
    }
    
    private var primaryAction: FABAction {
        contextActions.first ?? FABAction(
            id: "default",
            title: "Add",
            icon: "plus",
            color: .blue,
            action: {}
        )
    }
    
    // MARK: - Helper Views
    
    private func contextualActionButton(action: FABAction) -> some View {
        Button(action: action.action) {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.title3)
                    .foregroundColor(action.color)
                    .frame(width: smallButtonSize, height: smallButtonSize)
                    .background(
                        Circle()
                            .fill(action.color.opacity(0.15))
                    )
                
                Text(action.title)
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

// MARK: - Supporting Types

enum FABContext {
    case dashboard
    case accountsList
    case accountDetail(Account)
    case transactions
}

struct FABAction {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

// MARK: - Preview Provider
struct ContextualFAB_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                Text("Account Detail Preview")
                    .font(.title)
                Spacer()
            }
            
            ContextualFAB(
                context: .accountDetail(Account(
                    userId: "test",
                    name: "Test Account",
                    type: .current
                )),
                isExpanded: .constant(false)
            )
        }
    }
}