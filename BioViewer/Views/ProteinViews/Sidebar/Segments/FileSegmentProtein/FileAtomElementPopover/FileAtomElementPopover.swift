//
//  FileAtomElementPopover.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 23/11/21.
//

import SwiftUI

struct FileAtomElementPopover: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var carbonFraction: CGFloat = 0.0
    @State var hydrogenFraction: CGFloat = 0.0
    @State var nitrogenFraction: CGFloat = 0.0
    @State var oxygenFraction: CGFloat = 0.0
    @State var sulfurFraction: CGFloat = 0.0
    @State var othersFraction: CGFloat = 0.0
    
    private enum AnimationConstants {
        static let duration: Double = 0.8
    }
    
    func setAtomFractions() {
        guard let totalAtoms = proteinViewModel.dataSource.proteins.first?.atomCount else {
            return
        }
        guard let carbonCount = proteinViewModel.dataSource.proteins.first?.atomArrayComposition.carbonCount else {
            return
        }
        guard let hydrogenCount = proteinViewModel.dataSource.proteins.first?.atomArrayComposition.hydrogenCount else {
            return
        }
        guard let nitrogenCount = proteinViewModel.dataSource.proteins.first?.atomArrayComposition.nitrogenCount else {
            return
        }
        guard let oxygenCount = proteinViewModel.dataSource.proteins.first?.atomArrayComposition.oxygenCount else {
            return
        }
        guard let sulfurCount = proteinViewModel.dataSource.proteins.first?.atomArrayComposition.sulfurCount else {
            return
        }
        guard let othersCount = proteinViewModel.dataSource.proteins.first?.atomArrayComposition.othersCount else {
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
        VStack {
            ZStack {
                // Others
                Circle()
                    .trim(from: 0, to: othersFraction)
                    .stroke(proteinViewModel.renderer.scene.unknownAtomColor,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Sulfur
                Circle()
                    .trim(from: 0, to: sulfurFraction)
                    .stroke(proteinViewModel.renderer.scene.sAtomColor,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Oxygen
                Circle()
                    .trim(from: 0, to: oxygenFraction)
                    .stroke(proteinViewModel.renderer.scene.oAtomColor,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Nitrogen
                Circle()
                    .trim(from: 0, to: nitrogenFraction)
                    .stroke(proteinViewModel.renderer.scene.nAtomColor,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Hydrogen
                Circle()
                    .trim(from: 0, to: hydrogenFraction)
                    .stroke(proteinViewModel.renderer.scene.hAtomColor,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Carbon
                Circle()
                    .trim(from: 0, to: carbonFraction)
                    .stroke(proteinViewModel.renderer.scene.cAtomColor,
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
            }
            .padding(36)
            .frame(width: 250, height: 250)
            VStack {
                FileAtomElementRow(element: "Carbon")
                FileAtomElementRow(element: "Hydrogen")
                FileAtomElementRow(element: "Nitrogen")
                FileAtomElementRow(element: "Oxygen")
                FileAtomElementRow(element: "Sulfur")
                FileAtomElementRow(element: "Others")
                Divider()
                    .padding(.horizontal, 24)
                FileAtomElementRow(element: "Total", bold: true)
            }
            .padding(.bottom, 24)
        }
        .frame(minWidth: 350)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: AnimationConstants.duration)) {
                setAtomFractions()
            }
        }
    }
}

struct FileAtomElementPopover_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomElementPopover()
    }
}
