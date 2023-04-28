//
//  GraphicsSettingsSegment.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/4/23.
//

import SwiftUI

struct GraphicsSettingsSegment: View {
    
    @EnvironmentObject var graphicsSettings: ProteinGraphicsSettings
    
    var body: some View {
        List {
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(
                content: {
                    PickerRow(
                        optionName: NSLocalizedString("MetalFX Upscaling", comment: ""),
                        selection: $graphicsSettings.metalFXUpscalingMode
                    )
                },
                header: {
                    Text(NSLocalizedString("Graphics settings", comment: ""))
                        .padding(.top, 52)
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
