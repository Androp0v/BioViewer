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
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomArrayComposition.carbonCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomType.CARBON)]
            case "hydrogen":
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomArrayComposition.hydrogenCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomType.HYDROGEN)]
            case "nitrogen":
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomArrayComposition.nitrogenCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomType.NITROGEN)]
            case "oxygen":
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomArrayComposition.oxygenCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomType.OXYGEN)]
            case "sulfur":
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomArrayComposition.sulfurCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomType.SULFUR)]
            case "others":
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomArrayComposition.othersCount
                self.elementColor = proteinViewModel.elementColors[Int(AtomType.UNKNOWN)]
            case "total":
                self.atomCount = proteinViewModel.dataSource.getFirstProtein()?.atomCount
                self.elementColor = .clear
            default:
                self.atomCount = -1
                self.elementColor = .clear
            }
            self.totalAtom = proteinViewModel.dataSource.getFirstProtein()?.atomCount
        }
    }
}

struct FileAtomElementRow_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomElementRow(element: "Carbon")
    }
}
