//
//  VisualizationSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/11/22.
//

import Foundation
import SwiftUI

struct VisualizationSection: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    var body: some View {
        Section(
            header:
                Text(NSLocalizedString("Visualization", comment: ""))
                    .padding(.bottom, 4),
            content: {
            
                PersistentDisclosureGroup(
                    for: .visualizationGroup,
                    defaultOpen: true,
                    content: {
                        
                        switch proteinViewModel.visualization {
                        case .solidSpheres:
                            
                            // MARK: - Solid spheres
                            
                            PersistentDisclosureGroup(
                                for: .solidSpheresRadiusGroup,
                                defaultOpen: false,
                                content: {
                                    if proteinViewModel.solidSpheresRadiusOption == .fixed {
                                        SliderRow(
                                            title: NSLocalizedString("Size", comment: ""),
                                            value: $proteinViewModel.solidSpheresFixedAtomRadii,
                                            minValue: 0.2,
                                            maxValue: 2.0
                                        )
                                    } else if proteinViewModel.solidSpheresRadiusOption == .vanDerWaals {
                                        SliderRow(
                                            title: NSLocalizedString("Scale", comment: ""),
                                            value: $proteinViewModel.solidSpheresVDWScale,
                                            minValue: 0.1,
                                            maxValue: 1.5
                                        )
                                    }
                                },
                                label: {
                                    PickerRow(
                                        optionName: "Radius",
                                        selection: $proteinViewModel.solidSpheresRadiusOption
                                    )
                                        #if targetEnvironment(macCatalyst)
                                        .padding(.leading, 8)
                                        #else
                                        .padding(.trailing, 16)
                                        #endif
                                }
                            )
                        case .ballAndStick:
                            
                            // MARK: - Ball and Stick
                            
                            PersistentDisclosureGroup(
                                for: .ballAndStickRadiusGroup,
                                defaultOpen: false,
                                content: {
                                    if proteinViewModel.ballAndStickRadiusOption == .fixed {
                                        SliderRow(
                                            title: NSLocalizedString("Size", comment: ""),
                                            value: $proteinViewModel.ballAndSticksFixedAtomRadii,
                                            minValue: 0.2,
                                            maxValue: 0.6
                                        )
                                    } else if proteinViewModel.ballAndStickRadiusOption == .scaledVDW {
                                        SliderRow(
                                            title: NSLocalizedString("Scale", comment: ""),
                                            value: $proteinViewModel.ballAndSticksVDWScale,
                                            minValue: 0.2,
                                            maxValue: 0.4
                                        )
                                    }
                                },
                                label: {
                                    PickerRow(
                                        optionName: "Radius",
                                        selection: $proteinViewModel.ballAndStickRadiusOption
                                    )
                                        #if targetEnvironment(macCatalyst)
                                        .padding(.leading, 8)
                                        #else
                                        .padding(.trailing, 16)
                                        #endif
                                }
                            )
                        }
                    },
                    label: {
                        PickerRow(
                            optionName: "View as",
                            selection: $proteinViewModel.visualization
                        )
                            #if targetEnvironment(macCatalyst)
                            .padding(.leading, 8)
                            #else
                            .padding(.trailing, 16)
                            #endif
                    }
                )
                            
                // TODO: Surface representation
                /*
                SwitchRow(title: "Show solvent-excluded surface", toggledVariable: $proteinViewModel.showSurface)
                 */
            }
        )
        #if targetEnvironment(macCatalyst)
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, 8)
        #endif
    }
}
