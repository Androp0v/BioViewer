//
//  VisualizationSection.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/11/22.
//

import Foundation
import SwiftUI

struct VisualizationSection: View {
    
    @Environment(ProteinVisualizationViewModel.self) var visualizationViewModel: ProteinVisualizationViewModel
    
    var body: some View {
        @Bindable var visualizationViewModel = visualizationViewModel
        Section(
            header:
                Text(NSLocalizedString("Visualization", comment: ""))
                    .padding(.bottom, 4),
            content: {
            
                PersistentDisclosureGroup(
                    for: .visualizationGroup,
                    defaultOpen: true,
                    content: {
                        
                        switch visualizationViewModel.visualization {
                        case .solidSpheres:
                            
                            // MARK: - Solid spheres
                            
                            PersistentDisclosureGroup(
                                for: .solidSpheresRadiusGroup,
                                defaultOpen: false,
                                content: {
                                    if visualizationViewModel.solidSpheresRadiusOption == .fixed {
                                        SliderRow(
                                            title: NSLocalizedString("Size", comment: ""),
                                            value: $visualizationViewModel.solidSpheresFixedAtomRadii,
                                            minValue: 0.2,
                                            maxValue: 2.0
                                        )
                                    } else if visualizationViewModel.solidSpheresRadiusOption == .vanDerWaals {
                                        SliderRow(
                                            title: NSLocalizedString("Scale", comment: ""),
                                            value: $visualizationViewModel.solidSpheresVDWScale,
                                            minValue: 0.1,
                                            maxValue: 1.5
                                        )
                                    }
                                },
                                label: {
                                    PickerRow(
                                        optionName: "Radius",
                                        selection: $visualizationViewModel.solidSpheresRadiusOption
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
                                    if visualizationViewModel.ballAndStickRadiusOption == .fixed {
                                        SliderRow(
                                            title: NSLocalizedString("Size", comment: ""),
                                            value: $visualizationViewModel.ballAndSticksFixedAtomRadii,
                                            minValue: 0.2,
                                            maxValue: 0.6
                                        )
                                    } else if visualizationViewModel.ballAndStickRadiusOption == .scaledVDW {
                                        SliderRow(
                                            title: NSLocalizedString("Scale", comment: ""),
                                            value: $visualizationViewModel.ballAndSticksVDWScale,
                                            minValue: 0.2,
                                            maxValue: 0.4
                                        )
                                    }
                                },
                                label: {
                                    PickerRow(
                                        optionName: "Radius",
                                        selection: $visualizationViewModel.ballAndStickRadiusOption
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
                            selection: $visualizationViewModel.visualization
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
