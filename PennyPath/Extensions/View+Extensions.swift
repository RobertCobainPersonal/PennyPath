//
//  View+Extensions.swift
//  PennyPath
//
//  Created by Robert Cobain on 09/06/2025.
//

import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
#endif
