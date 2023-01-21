//
//  FileAtomElementRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 24/11/21.
//

import SwiftUI

struct FileCompositionItemRow: View {
        
    let itemName: String
    let itemColor: Color
    let itemCount: Int
    let fraction: Double
    
    func getPercentageString() -> String {
        return String(format: "%.2f", fraction * 100) + "%"
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
                .background(Circle().foregroundColor(itemColor))
            Text(itemName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(itemCount)")
                .frame(maxWidth: .infinity, alignment: .center)
            Text(getPercentageString())
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
    }
}

// MARK: - Previews

struct FileCompositionItemRow_Previews: PreviewProvider {
    static var previews: some View {
        FileCompositionItemRow(itemName: "Carbon", itemColor: .green, itemCount: 130, fraction: 0.15)
    }
}
