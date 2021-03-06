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
    let stepSize: Float
    
    func getNumberFormatter(min: Float, max: Float) -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimum = min as NSNumber
        numberFormatter.maximum = max as NSNumber
        return numberFormatter
    }
    
    init(title: String, value: Binding<Float>, minValue: Float, maxValue: Float, stepSize: Float = 0.1) {
        self.title = title
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.stepSize = stepSize
    }
    
    var body: some View {
        HStack {
            Text(title)
            Slider(value: $value, in: minValue...maxValue)
                .frame(maxWidth: .infinity)
            #if targetEnvironment(macCatalyst)
            Stepper(value: $value, in: minValue...maxValue, step: stepSize) {
                TextField("Value",
                          value: $value,
                          formatter: getNumberFormatter(min: minValue, max: maxValue))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(maxWidth: 64)
            #endif
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
