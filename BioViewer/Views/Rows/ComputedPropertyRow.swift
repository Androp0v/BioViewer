//
//  ComputedPropertyRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 3/12/21.
//

import SwiftUI

struct ComputedPropertyRow: View {
    
    let propertyName: String
    let units: String
    
    @Binding var value: Float?
    @Binding var errorInterval: Float?
    
    func getValueString() -> String {
        guard let value = value else {
            return NSLocalizedString("Unknown", comment: "")
        }
        return String(format: "%.2f", value)
    }
    
    func getErrorIntervalString() -> String {
        guard let errorInterval = errorInterval else {
            return NSLocalizedString("Unknown", comment: "")
        }
        return String(format: "%.2f", errorInterval)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            
            if value == nil {
                Button(action: {
                    // TO-DO
                }, label: {
                    Text(NSLocalizedString("Compute ", comment: "") + propertyName)
                })
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.blue)
            } else {
                Text(propertyName.capitalized)
            }
            
            Spacer()
            
            if value != nil && errorInterval != nil {
                Text("\(getValueString()) ± \(getErrorIntervalString())")
                UnitTextView(inputString: units, baseLine: 8.0)
            } else if value != nil {
                Text("\(getValueString())")
                UnitTextView(inputString: units, baseLine: 8.0)
            } else {
                Text("Unkwnown").redacted(reason: .placeholder)
                UnitTextView(inputString: units, baseLine: 8.0)
            }
        }
    }
}

struct ComputedPropertyRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ComputedPropertyRow(propertyName: "volume",
                                units: "Å^{3}",
                                value: .constant(8842.4),
                                errorInterval: .constant(26.1))
            ComputedPropertyRow(propertyName: "volume",
                                units: "Å^{3}",
                                value: .constant(nil),
                                errorInterval: .constant(nil))
        }
    }
}
