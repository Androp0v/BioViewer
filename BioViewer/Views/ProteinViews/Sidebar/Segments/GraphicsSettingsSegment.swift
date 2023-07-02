//
//  GraphicsSettingsSegment.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/4/23.
//

import SwiftUI

struct GraphicsSettingsSegment: View {
    
    @EnvironmentObject var graphicsSettings: ProteinGraphicsSettings
    
    let ssaaFormatter: NumberFormatter
    let metalFXFactorFormatter: NumberFormatter
    
    init() {
        let ssaaFormatter = NumberFormatter()
        ssaaFormatter.numberStyle = .decimal
        ssaaFormatter.minimumSignificantDigits = 3
        ssaaFormatter.minimum = 1.0
        ssaaFormatter.maximum = 2.0
        self.ssaaFormatter = ssaaFormatter
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumSignificantDigits = 3
        formatter.minimum = 1.0
        formatter.maximum = 2.0
        self.metalFXFactorFormatter = formatter
    }
    
    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(
                content: {
                    PersistentDisclosureGroup(
                        for: .metalFXUpscalingSettings,
                        defaultOpen: AppState.hasMetalFXUpscalingSupport(),
                        content: {
                            InputWithButtonRow(
                                title: "SSAA",
                                value: $graphicsSettings.ssaaFactor,
                                buttonTitle: "Apply",
                                action: {
                                    // TODO: Implement this
                                },
                                formatter: ssaaFormatter
                            )
                            InputWithButtonRow(
                                title: "Upscaling factor",
                                value: $graphicsSettings.metalFXFactor,
                                buttonTitle: "Apply",
                                action: {
                                    // TODO: Implement this
                                },
                                formatter: ssaaFormatter
                            )
                        },
                        label: {
                            PickerRow(
                                optionName: NSLocalizedString("MetalFX Upscaling", comment: ""),
                                selection: $graphicsSettings.metalFXUpscalingMode
                            )
                            .disabled(!AppState.hasMetalFXUpscalingSupport())
                            #if targetEnvironment(macCatalyst)
                            .padding(.leading, 8)
                            #else
                            .padding(.trailing, 16)
                            #endif
                        }
                    )
                },
                header: {
                    Text(NSLocalizedString("Graphics settings", comment: ""))
                        .padding(.bottom, 4)
                }
            )
            #if targetEnvironment(macCatalyst)
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 8))
            #endif
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .listStyle(DefaultListStyle())
    }
}

struct GraphicsSettingsSegment_Previews: PreviewProvider {
    static var previews: some View {
        GraphicsSettingsSegment()
    }
}
