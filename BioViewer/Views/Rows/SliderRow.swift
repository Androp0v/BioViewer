//
//  SliderRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 10/12/21.
//

import SwiftUI

struct SliderRow: View {
    
    let title: String
    @Binding var value: Float
    let minValue: Float
    let maxValue: Float
    
    var body: some View {
        HStack {
            Text(title)
            Slider(value: $value, in: minValue...maxValue)
        }
    }
}

struct SliderRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SliderRow(title: "Strength",
                      value: .constant(0.3),
                      minValue: 0.0,
                      maxValue: 1.0)
        }
    }
}
