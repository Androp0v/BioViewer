//
//  FileAtomElementRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/11/21.
//

import SwiftUI

struct FileAtomElementRow: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    let element: String
    let bold: Bool
    @State var elementColor: Color?
    @State var atomCount: Int?
    @State var totalAtom: Int?
    
    init(element: String, bold: Bool = false) {
        
        self.element = element
        self.bold = bold
    }
    
    func getAtomCountString() -> String {
        guard let atomCount = atomCount, atomCount >= 0 else {
            return "-"
        }
        return String(atomCount)
    }
    
    func getPercentageString() -> String {
        guard let atomCount = atomCount, let totalAtom = totalAtom else {
            return "-"
        }
        let atomFraction = Float(atomCount) / Float(totalAtom)
        return String(format: "%.2f", atomFraction * 100) + "%"
    }
    
    var body: some View {
        let columns = [
            GridItem(.fixed(12)),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        LazyVGrid(columns: columns) {
            Circle()
                .stroke(Color(uiColor: .separator),
                        style: StrokeStyle(lineWidth: 1))
                .background(Circle().foregroundColor(elementColor))
            if !bold {
                Text(element)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(getAtomCountString())
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(getPercentageString())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text(element)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(getAtomCountString())
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(getPercentageString())
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
        .onAppear {
            switch element.lowercased() {
            case "carbon":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.carbonCount
                self.elementColor = proteinViewModel.renderer.scene.cAtomColor
            case "hydrogen":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.hydrogenCount
                self.elementColor = proteinViewModel.renderer.scene.hAtomColor
            case "nitrogen":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.nitrogenCount
                self.elementColor = proteinViewModel.renderer.scene.nAtomColor
            case "oxygen":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.oxygenCount
                self.elementColor = proteinViewModel.renderer.scene.oAtomColor
            case "sulfur":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.sulfurCount
                self.elementColor = proteinViewModel.renderer.scene.sAtomColor
            case "others":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomArrayComposition.othersCount
                self.elementColor = proteinViewModel.renderer.scene.unknownAtomColor
            case "total":
                self.atomCount = proteinViewModel.dataSource.files.first?.protein.atomCount
                self.elementColor = .clear
            default:
                self.atomCount = -1
                self.elementColor = .clear
            }
            self.totalAtom = proteinViewModel.dataSource.files.first?.protein.atomCount
        }
    }
}

struct FileAtomElementRow_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomElementRow(element: "Carbon")
    }
}
