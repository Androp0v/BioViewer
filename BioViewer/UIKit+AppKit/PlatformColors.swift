//
//  PlatformColors.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 13/6/24.
//

import SwiftUI

extension Color {
    #if os(iOS)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator)
    static let opaqueSeparator = Color(uiColor: .opaqueSeparator)
    static let systemBackground = Color(uiColor: .systemBackground)
    static let systemFill = Color(uiColor: .systemFill)
    static let secondarySystemFill = Color(uiColor: .secondarySystemFill)
    static let tertiarySystemFill = Color(uiColor: .tertiarySystemFill)
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    static let label = Color(uiColor: .label)
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
    #elseif os(macOS)
    static let secondaryLabel = Color(nsColor: .secondaryLabelColor)
    static let separator = Color(nsColor: .separatorColor)
    static let opaqueSeparator = Color(nsColor: .separatorColor)
    static let systemBackground = Color(nsColor: .windowBackgroundColor)
    static let systemFill = Color(nsColor: .systemFill)
    static let secondarySystemFill = Color(nsColor: .secondarySystemFill)
    static let tertiarySystemFill = Color(nsColor: .tertiarySystemFill)
    static let secondarySystemBackground = Color(nsColor: .secondarySystemFill)
    static let label = Color(nsColor: .labelColor)
    static let tertiaryLabel = Color(nsColor: .tertiaryLabelColor)
    #endif
}
