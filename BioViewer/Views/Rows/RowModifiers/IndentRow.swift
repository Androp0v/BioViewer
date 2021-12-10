//
//  IndentRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/12/21.
//

import Foundation
import SwiftUI

struct IndentRow: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 24)
            content
        }
    }
}

extension View {
    func indentRow() -> some View {
        modifier(IndentRow())
    }
}
