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
        guard let totalAtoms = proteinViewModel.dataSource.modelForFile(file: file)?.atomCount else {
            return
        }
        guard let carbonCount = proteinViewModel.dataSource.modelForFile(file: file)?.atomArrayComposition.carbonCount else {
            return
        }
        guard let hydrogenCount = proteinViewModel.dataSource.modelForFile(file: file)?.atomArrayComposition.hydrogenCount else {
            return
        }
        guard let nitrogenCount = proteinViewModel.dataSource.modelForFile(file: file)?.atomArrayComposition.nitrogenCount else {
            return
        }
        guard let oxygenCount = proteinViewModel.dataSource.modelForFile(file: file)?.atomArrayComposition.oxygenCount else {
            return
        }
        guard let sulfurCount = proteinViewModel.dataSource.modelForFile(file: file)?.atomArrayComposition.sulfurCount else {
            return
        }
        guard let othersCount = proteinViewModel.dataSource.modelForFile(file: file)?.atomArrayComposition.othersCount else {
            return
        }
        
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
                proteinViewModel.elementColors[Int(AtomType.UNKNOWN)]
                    .frame(width: othersFraction * geometry.size.width)
                // Sulfur
                proteinViewModel.elementColors[Int(AtomType.SULFUR)]
                    .frame(width: sulfurFraction * geometry.size.width)
                // Oxygen
                proteinViewModel.elementColors[Int(AtomType.OXYGEN)]
                    .frame(width: oxygenFraction * geometry.size.width)
                // Nitrogen
                proteinViewModel.elementColors[Int(AtomType.NITROGEN)]
                    .frame(width: nitrogenFraction * geometry.size.width)
                // Hydrogen
                proteinViewModel.elementColors[Int(AtomType.HYDROGEN)]
                    .frame(width: hydrogenFraction * geometry.size.width)
                // Carbon
                proteinViewModel.elementColors[Int(AtomType.CARBON)]
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
