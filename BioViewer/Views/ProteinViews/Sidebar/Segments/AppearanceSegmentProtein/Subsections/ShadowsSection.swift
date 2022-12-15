//
//  ShadowsSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/11/22.
//

import Foundation
import SwiftUI

struct ShadowsSection: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    var body: some View {
        Section(
            header: Text(NSLocalizedString("Shadows", comment: ""))
                .padding(.bottom, 4),
            content: {
                if AppState.hasSamplerCompareSupport() {
                    PersistentDisclosureGroup(
                        for: .shadowGroup,
                        defaultOpen: false,
                        content: {
                            SliderRow(
                                title: NSLocalizedString("Strength", comment: ""),
                                value: $proteinViewModel.renderer.scene.shadowStrength,
                                minValue: 0.0,
                                maxValue: 1.0
                            )
                            .disabled(!proteinViewModel.renderer.scene.hasShadows)
                        },
                        label: {
                            SwitchRow(
                                title: NSLocalizedString("Cast shadows", comment: ""),
                                toggledVariable: $proteinViewModel.renderer.scene.hasShadows
                            )
                            #if targetEnvironment(macCatalyst)
                            .padding(.leading, 8)
                            #else
                            .padding(.trailing, 16)
                            #endif
                        }
                    )
                }
                
                PersistentDisclosureGroup(
                    for: .depthCueingGroup,
                    defaultOpen: false,
                    content: {
                        SliderRow(
                            title: NSLocalizedString("Strength", comment: ""),
                            value: $proteinViewModel.renderer.scene.depthCueingStrength,
                            minValue: 0.0,
                            maxValue: 1.0
                        )
                        .disabled(!proteinViewModel.renderer.scene.hasDepthCueing)
                    }, label: {
                        SwitchRow(
                            title: NSLocalizedString("Depth cueing", comment: ""),
                            toggledVariable: $proteinViewModel.renderer.scene.hasDepthCueing
                        )
                        #if targetEnvironment(macCatalyst)
                        .padding(.leading, 8)
                        #else
                        .padding(.trailing, 16)
                        #endif
                    }
                )
            }
        )
        #if targetEnvironment(macCatalyst)
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, 8)
        #endif
    }
}
