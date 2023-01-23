//
//  ShadowsSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/11/22.
//

import Foundation
import SwiftUI

struct ShadowsSection: View {
    
    @EnvironmentObject var shadowsViewModel: ProteinShadowsViewModel
    
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
                                value: $shadowsViewModel.shadowStrength,
                                minValue: 0.0,
                                maxValue: 1.0
                            )
                            .disabled(!shadowsViewModel.hasShadows)
                        },
                        label: {
                            SwitchRow(
                                title: NSLocalizedString("Cast shadows", comment: ""),
                                toggledVariable: $shadowsViewModel.hasShadows
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
                            value: $shadowsViewModel.depthCueingStrength,
                            minValue: 0.0,
                            maxValue: 1.0
                        )
                        .disabled(!shadowsViewModel.hasDepthCueing)
                    }, label: {
                        SwitchRow(
                            title: NSLocalizedString("Depth cueing", comment: ""),
                            toggledVariable: $shadowsViewModel.hasDepthCueing
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
