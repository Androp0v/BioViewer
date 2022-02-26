//
//  BioViewerCommands.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 11/1/22.
//

import SwiftUI

struct FocusedProteinViewValue: FocusedValueKey {
    typealias Value = ProteinViewModel
}

extension FocusedValues {
    var proteinViewModel: FocusedProteinViewValue.Value? {
        get {
                self[FocusedProteinViewValue.self]
        }
        set {
            // Update the reference to the currently focused scene on the AppState
            AppState.shared.focusedViewModel = newValue
        }
    }
}

struct BioViewerCommands: Commands {
        
    var body: some Commands {
        
        // MARK: - Files
        CommandGroup(after: .newItem) {
            Button(NSLocalizedString("Remove all files", comment: "")) {
                AppState.shared.focusedViewModel?.dataSource.removeAllFilesFromDatasource()
            }
            .keyboardShortcut(.delete)
        }
        
        // MARK: - View
        CommandGroup(before: CommandGroupPlacement.toolbar) {
            
            Section {
            
                Button(NSLocalizedString("View as space-filling spheres", comment: "")) {
                    AppState.shared.focusedViewModel?.visualization = .solidSpheres
                }
                .keyboardShortcut("1")
                
                Button(NSLocalizedString("View as ball and stick", comment: "")) {
                    AppState.shared.focusedViewModel?.visualization = .ballAndStick
                }
                .keyboardShortcut("2")
            }
        }
        
        // MARK: - Color
        CommandMenu(NSLocalizedString("Color", comment: "")) {
            Section {
                Button(NSLocalizedString("Color by element", comment: "")) {
                    AppState.shared.focusedViewModel?.colorBy = ProteinColorByOption.element
                }
                .keyboardShortcut("1", modifiers: [.command, .shift])
                
                Button(NSLocalizedString("Color by subunit", comment: "")) {
                    AppState.shared.focusedViewModel?.colorBy = ProteinColorByOption.subunit
                }
                .keyboardShortcut("2", modifiers: [.command, .shift])
            }
        }
    }
}
