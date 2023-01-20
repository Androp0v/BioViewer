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
                Text("\(atomCount ?? 0)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(getPercentageString())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text(element)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(atomCount ?? 0)")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(getPercentageString())
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
        .task {
            guard let file = proteinViewModel.dataSource.getFirstFile() else { return }
            guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
            var atomArrayComposition = AtomArrayComposition()
            for protein in proteins {
                atomArrayComposition += protein.atomArrayComposition
            }
            
            switch element.lowercased() {
            case "carbon":
                self.atomCount = atomArrayComposition.carbonCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomElement.carbon.rawValue)]
            case "hydrogen":
                self.atomCount = atomArrayComposition.hydrogenCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomElement.hydrogen.rawValue)]
            case "nitrogen":
                self.atomCount = atomArrayComposition.nitrogenCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomElement.nitrogen.rawValue)]
            case "oxygen":
                self.atomCount = atomArrayComposition.oxygenCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomElement.oxygen.rawValue)]
            case "sulfur":
                self.atomCount = atomArrayComposition.sulfurCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomElement.sulfur.rawValue)]
            case "others":
                self.atomCount = atomArrayComposition.othersCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomElement.unknown.rawValue)]
            case "total":
                self.atomCount = atomArrayComposition.totalCount
                self.elementColor = .clear
            default:
                self.atomCount = -1
                self.elementColor = .clear
            }
            self.totalAtom = atomArrayComposition.totalCount
        }
    }
}

struct FileAtomElementRow_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomElementRow(element: "Carbon")
    }
}
