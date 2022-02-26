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
        guard let totalAtoms = proteinViewModel.dataSource.files.first?.protein.atomCount else {
            return
        }
        guard let carbonCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.carbonCount else {
            return
        }
        guard let hydrogenCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.hydrogenCount else {
            return
        }
        guard let nitrogenCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.nitrogenCount else {
            return
        }
        guard let oxygenCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.oxygenCount else {
            return
        }
        guard let sulfurCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.sulfurCount else {
            return
        }
        guard let othersCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.othersCount else {
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
                    .stroke(proteinViewModel.elementColors[5],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Sulfur
                Circle()
                    .trim(from: 0, to: sulfurFraction)
                    .stroke(proteinViewModel.elementColors[4],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Oxygen
                Circle()
                    .trim(from: 0, to: oxygenFraction)
                    .stroke(proteinViewModel.elementColors[3],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Nitrogen
                Circle()
                    .trim(from: 0, to: nitrogenFraction)
                    .stroke(proteinViewModel.elementColors[2],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Hydrogen
                Circle()
                    .trim(from: 0, to: hydrogenFraction)
                    .stroke(proteinViewModel.elementColors[1],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Carbon
                Circle()
                    .trim(from: 0, to: carbonFraction)
                    .stroke(proteinViewModel.elementColors[0],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
            }
            .padding(36)
            .frame(width: 250, height: 250)
            VStack {
                VStack {
                    Text("Number of atoms of each element")
                        .font(.headline)
                        .bold()
                    Divider()
                }
                FileAtomElementRow(element: "Carbon")
                FileAtomElementRow(element: "Hydrogen")
                FileAtomElementRow(element: "Nitrogen")
                FileAtomElementRow(element: "Oxygen")
                FileAtomElementRow(element: "Sulfur")
                FileAtomElementRow(element: "Others")
                Divider()
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
