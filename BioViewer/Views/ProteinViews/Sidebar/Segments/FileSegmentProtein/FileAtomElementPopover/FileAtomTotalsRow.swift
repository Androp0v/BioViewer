//
//  FileAtomTotalsRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/1/23.
//

import SwiftUI

struct FileAtomTotalsRow: View {
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @State var total: Int?

    var body: some View {
        
        let columns = [
            GridItem(.fixed(12)),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        LazyVGrid(columns: columns) {
            Circle()
                .foregroundColor(.clear)
            Group {
                Text("Total: ")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(total ?? 0)")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("100.00%")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .bold()
        }
        .padding(.horizontal)
        .task {
            guard let file = proteinViewModel.dataSource.getFirstFile() else { return }
            guard let proteins = proteinViewModel.dataSource.modelsForFile(file: file) else { return }
            var totalAtomCount: Int = 0
            for protein in proteins {
                totalAtomCount += protein.elementComposition.totalCount
            }
            self.total = totalAtomCount
        }
    }
}

struct FileAtomTotalsRow_Previews: PreviewProvider {
    static var previews: some View {
        FileAtomTotalsRow()
    }
}
