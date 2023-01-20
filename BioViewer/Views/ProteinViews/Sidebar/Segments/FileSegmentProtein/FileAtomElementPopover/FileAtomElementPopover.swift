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
    
    @State var atomArrayComposition = AtomArrayComposition()
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
                
        guard let file = proteinViewModel.dataSource.getFirstFile() else { return }
        guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
        atomArrayComposition = AtomArrayComposition()
        for protein in proteins {
            atomArrayComposition += protein.atomArrayComposition
        }
        
        carbonFraction = CGFloat(atomArrayComposition.carbonCount)
        / CGFloat(atomArrayComposition.totalCount)
        
        hydrogenFraction = CGFloat(atomArrayComposition.hydrogenCount)
        / CGFloat(atomArrayComposition.totalCount) + carbonFraction
        
        nitrogenFraction = CGFloat(atomArrayComposition.nitrogenCount)
        / CGFloat(atomArrayComposition.totalCount) + hydrogenFraction
        
        oxygenFraction = CGFloat(atomArrayComposition.oxygenCount)
        / CGFloat(atomArrayComposition.totalCount) + nitrogenFraction
        
        sulfurFraction = CGFloat(atomArrayComposition.sulfurCount)
        / CGFloat(atomArrayComposition.totalCount) + oxygenFraction
        
        othersFraction = CGFloat(atomArrayComposition.othersCount)
        / CGFloat(atomArrayComposition.totalCount) + sulfurFraction
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Others
                Circle()
                    .trim(from: 0, to: othersFraction)
                    .stroke(proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Sulfur
                Circle()
                    .trim(from: 0, to: sulfurFraction)
                    .stroke(proteinViewModel.elementColors[Int(AtomElement.sulfur.rawValue)],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Oxygen
                Circle()
                    .trim(from: 0, to: oxygenFraction)
                    .stroke(proteinViewModel.elementColors[Int(AtomElement.oxygen.rawValue)],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Nitrogen
                Circle()
                    .trim(from: 0, to: nitrogenFraction)
                    .stroke(proteinViewModel.elementColors[Int(AtomElement.nitrogen.rawValue)],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Hydrogen
                Circle()
                    .trim(from: 0, to: hydrogenFraction)
                    .stroke(proteinViewModel.elementColors[Int(AtomElement.hydrogen.rawValue)],
                            style: StrokeStyle(lineWidth: 40) )
                    .rotationEffect(.degrees(-90))
                // Carbon
                Circle()
                    .trim(from: 0, to: carbonFraction)
                    .stroke(proteinViewModel.elementColors[Int(AtomElement.carbon.rawValue)],
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
            .environmentObject(proteinViewModel)
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
