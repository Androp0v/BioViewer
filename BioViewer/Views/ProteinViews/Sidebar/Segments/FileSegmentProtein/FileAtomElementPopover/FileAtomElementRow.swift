//
//  FileAtomElementRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/11/21.
//

import SwiftUI

struct FileAtomElementRow: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    let element: AtomElement
    @State var elementColor: Color?
    @State var atomCount: Int?
    @State var totalAtom: Int?
    
    init(element: AtomElement) {
        self.element = element
    }
    
    func getPercentageString() -> String {
        guard let atomCount = atomCount, let totalAtom = totalAtom else {
            return "0.00%"
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
            Text(element.longName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(atomCount ?? 0)")
                .frame(maxWidth: .infinity, alignment: .center)
            Text(getPercentageString())
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
        .task {
            guard let file = proteinViewModel.dataSource.getFirstFile() else { return }
            guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
            var atomArrayComposition = ProteinElementComposition()
            for protein in proteins {
                atomArrayComposition += protein.elementComposition
            }
            self.atomCount = atomArrayComposition.elementCounts[element]
            self.elementColor = proteinViewModel.elementColors[Int(element.rawValue)]
            self.totalAtom = atomArrayComposition.totalCount
        }
    }
}

struct FileAtomElementRow_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomElementRow(element: .carbon)
    }
}
