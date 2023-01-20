//
//  InfoAtomsCapsule.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/3/22.
//

import SwiftUI

struct InfoAtomsCapsule: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    let file: ProteinFile
    
    @State var carbonFraction: CGFloat = 0.0
    @State var hydrogenFraction: CGFloat = 0.0
    @State var nitrogenFraction: CGFloat = 0.0
    @State var oxygenFraction: CGFloat = 0.0
    @State var sulfurFraction: CGFloat = 0.0
    @State var othersFraction: CGFloat = 0.0
        
    func setAtomFractions() {
        guard let protein = proteinViewModel.dataSource.modelsForFile(file: file)?.first else {
            return
        }
        let totalAtoms = protein.atomCount
        let carbonCount = protein.atomArrayComposition.elementCounts[.carbon] ?? 0
        let hydrogenCount = protein.atomArrayComposition.elementCounts[.hydrogen] ?? 0
        let nitrogenCount = protein.atomArrayComposition.elementCounts[.nitrogen] ?? 0
        let oxygenCount = protein.atomArrayComposition.elementCounts[.oxygen] ?? 0
        let sulfurCount = protein.atomArrayComposition.elementCounts[.sulfur] ?? 0
        let othersCount = totalAtoms - protein.atomArrayComposition.importantElementCount
        
        carbonFraction = CGFloat(carbonCount) / CGFloat(totalAtoms)
        
        hydrogenFraction = CGFloat(hydrogenCount) / CGFloat(totalAtoms) + carbonFraction
        
        nitrogenFraction = CGFloat(nitrogenCount) / CGFloat(totalAtoms) + hydrogenFraction
        
        oxygenFraction = CGFloat(oxygenCount) / CGFloat(totalAtoms) + nitrogenFraction
        
        sulfurFraction = CGFloat(sulfurCount) / CGFloat(totalAtoms) + oxygenFraction
        
        othersFraction = CGFloat(othersCount) / CGFloat(totalAtoms) + sulfurFraction
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                // Others
                proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
                    .frame(width: othersFraction * geometry.size.width)
                // Sulfur
                proteinViewModel.elementColors[Int(AtomElement.sulfur.rawValue)]
                    .frame(width: sulfurFraction * geometry.size.width)
                // Oxygen
                proteinViewModel.elementColors[Int(AtomElement.oxygen.rawValue)]
                    .frame(width: oxygenFraction * geometry.size.width)
                // Nitrogen
                proteinViewModel.elementColors[Int(AtomElement.nitrogen.rawValue)]
                    .frame(width: nitrogenFraction * geometry.size.width)
                // Hydrogen
                proteinViewModel.elementColors[Int(AtomElement.hydrogen.rawValue)]
                    .frame(width: hydrogenFraction * geometry.size.width)
                // Carbon
                proteinViewModel.elementColors[Int(AtomElement.carbon.rawValue)]
                    .frame(width: carbonFraction * geometry.size.width)
            }
        }
        .onAppear {
            setAtomFractions()
        }
        .frame(height: 4)
        .mask(Capsule()
                .frame(height: 4)
        )
    }
}

/*
struct InfoAtomsCapsule_Previews: PreviewProvider {
    static var previews: some View {
        InfoAtomsCapsule()
            .environmentObject(ProteinViewModel())
    }
}
*/
