//
//  InfoAtomsRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/3/22.
//

import SwiftUI

struct InfoAtomsRow: View {
    let label: String
    let value: Int
    let isDisabled: Bool
    let file: ProteinFile
    
    @State var buttonToggle: Bool = false
    @EnvironmentObject var proteinViewModel: ProteinViewModel

    var body: some View {
                    
            VStack {
                HStack {
                    Text(label)
                    Text("\(value)")
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Spacer()
                }
                Spacer()
                    .frame(height: 8)
                
                HStack {
                    ZStack {
                        VStack(spacing: 6) {
                            InfoSegmentedCapsule(segments: getAtomElementSegments())
                                .shadow(color: .black.opacity(0.1), radius: 4)
                            
                            if let proteins = proteinViewModel.dataSource.modelsForFile(file: file),
                               proteins.first(where: { $0.residueComposition != nil }) != nil {
                                InfoSegmentedCapsule(segments: getAtomResiduesSegments())
                                    .shadow(color: .black.opacity(0.1), radius: 4)
                            }
                        }
                    }
                                
                    Button(action: {
                        buttonToggle.toggle()
                    },
                           label: {
                        Image(systemName: "info.circle")
                    })
                        .foregroundColor(Color.accentColor)
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isDisabled)
                        .popover(isPresented: $buttonToggle) {
                            FileCompositionView()
                                .environmentObject(proteinViewModel)
                        }
                }
            }
    }
    
    private func getAtomElementSegments() -> [InfoCapsuleSegment] {
        guard let protein = proteinViewModel.dataSource.modelsForFile(file: file)?.first else {
            return []
        }
        var segments = [InfoCapsuleSegment]()
        var importantTotal: Double = 0.0
        for element in AtomElement.importantElements {
            let elementFraction = Double(protein.elementComposition.elementCounts[element] ?? 0) / Double(protein.atomCount)
            segments.append(InfoCapsuleSegment(
                fraction: elementFraction,
                color: proteinViewModel.elementColors[Int(element.rawValue)]
            ))
            importantTotal += elementFraction
        }
        segments.append(InfoCapsuleSegment(
            fraction: 1 - importantTotal,
            color: proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
        ))
        return segments
    }
    
    private func getAtomResiduesSegments() -> [InfoCapsuleSegment] {
        guard let protein = proteinViewModel.dataSource.modelsForFile(file: file)?.first else {
            return []
        }
        guard let residueComposition = protein.residueComposition else {
             return []
        }
        var segments = [InfoCapsuleSegment]()
        for residue in Residue.allCases {
            let residueFraction = Double(residueComposition.residueCounts[residue] ?? 0) / Double(residueComposition.totalCount)
            segments.append(InfoCapsuleSegment(
                fraction: residueFraction,
                color: proteinViewModel.residueColors[Int(residue.rawValue)]
            ))
        }
        return segments
    }
}

/*
struct InfoAtomsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            InfoAtomsRow(label: "Número de átomos",
                         value: "58336",
                         isDisabled: false
                         file: ProteinFile())
        }
    }
}
*/
