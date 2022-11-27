//
//  AppearanceSegmentProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/5/21.
//

import SwiftUI

struct AppearanceSegmentProtein: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
            
    // MARK: - View
    
    var body: some View {
        List {
            
            // MARK: - General section
            // First section hast 64pt padding to account for the
            // space under the segmented control.
            Section(header: Text(NSLocalizedString("General", comment: ""))
                        .padding(.top, 52)
                        .padding(.bottom, 4)) {

                ColorPickerRow(title: NSLocalizedString("Background color", comment: ""),
                               selectedColor: $proteinViewModel.backgroundColor)
            }
            
            Section(header: Text(NSLocalizedString("Visualization", comment: ""))
                        .padding(.bottom, 4), content: {
                
                DisclosureGroup(
                    content: {
                        if proteinViewModel.visualization == .solidSpheres {
                            SolidSpheresRadiiPickerRow()
                            if proteinViewModel.solidSpheresRadiusOption == .fixed {
                                SliderRow(title: NSLocalizedString("Fixed radii", comment: ""),
                                          value: $proteinViewModel.solidSpheresFixedAtomRadii,
                                          minValue: 0.2,
                                          maxValue: 2.0)
                                    .indentRow()
                            } else if proteinViewModel.solidSpheresRadiusOption == .vanDerWaals {
                                SliderRow(title: NSLocalizedString("Scale", comment: ""),
                                          value: $proteinViewModel.solidSpheresVDWScale,
                                          minValue: 0.1,
                                          maxValue: 1.5)
                                    .indentRow()
                            }
                        }
                        
                        if proteinViewModel.visualization == .ballAndStick {
                            BallAndStickRadiiPickerRow()
                            if proteinViewModel.ballAndStickRadiusOption == .fixed {
                                SliderRow(title: NSLocalizedString("Fixed radii", comment: ""),
                                          value: $proteinViewModel.ballAndSticksFixedAtomRadii,
                                          minValue: 0.2,
                                          maxValue: 0.6)
                                    .indentRow()
                            } else if proteinViewModel.ballAndStickRadiusOption == .scaledVDW {
                                SliderRow(title: NSLocalizedString("Scale", comment: ""),
                                          value: $proteinViewModel.ballAndSticksVDWScale,
                                          minValue: 0.2,
                                          maxValue: 0.4)
                                    .indentRow()
                            }
                        }
                    },
                    label: {
                        VisualizationPickerRow()
                            #if targetEnvironment(macCatalyst)
                            .padding(.leading, 12)
                            #else
                            .padding(.trailing, 16)
                            #endif
                    }
                )
                            
                // TODO: Surface representation
                /*
                SwitchRow(title: "Show solvent-excluded surface", toggledVariable: $proteinViewModel.showSurface)
                 */
            })
            
            // MARK: - Color section
            
            if proteinViewModel.visualization == .solidSpheres || proteinViewModel.visualization == .ballAndStick {
                ColorSection()
            }
            
            // MARK: - Shadows section
            Section(header: Text(NSLocalizedString("Shadows", comment: ""))
                        .padding(.bottom, 4)) {
                if AppState.hasSamplerCompareSupport() {
                    SwitchRow(title: NSLocalizedString("Cast shadows", comment: ""),
                              toggledVariable: $proteinViewModel.renderer.scene.hasShadows)
                    if proteinViewModel.renderer.scene.hasShadows {
                        SliderRow(title: NSLocalizedString("Strength", comment: ""),
                                  value: $proteinViewModel.renderer.scene.shadowStrength,
                                  minValue: 0.0,
                                  maxValue: 1.0)
                            .indentRow()
                    }
                }
                SwitchRow(title: NSLocalizedString("Depth cueing", comment: ""),
                          toggledVariable: $proteinViewModel.renderer.scene.hasDepthCueing)
                if proteinViewModel.renderer.scene.hasDepthCueing {
                    // TO-DO:
                    /*
                    RangeRow(title: "Range:")
                        .indentRow()
                    */
                    SliderRow(title: NSLocalizedString("Strength", comment: ""),
                              value: $proteinViewModel.renderer.scene.depthCueingStrength,
                              minValue: 0.0,
                              maxValue: 1.0)
                        .indentRow()
                }
            }
            
            // MARK: - Camera section
            Section(header: Text(NSLocalizedString("Focal distance", comment: ""))
                        .padding(.bottom, 4)) {
                FocalLengthRow(focalLength: $proteinViewModel.cameraFocalLength)
            }

        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .listStyle(GroupedListStyle())
    }
}

// MARK: - SwiftUI Previews
struct AppearanceSegmentProtein_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSegmentProtein()
            .previewDevice("iPhone SE (2nd generation)")
            .previewLayout(.sizeThatFits)
            .environmentObject(ProteinViewModel())
    }
}
