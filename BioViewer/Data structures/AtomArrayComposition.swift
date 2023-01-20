//
//  AtomArrayComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import Foundation

public class AtomArrayComposition {
    var carbonCount: Int = 0
    var nitrogenCount: Int = 0
    var hydrogenCount: Int = 0
    var oxygenCount: Int = 0
    var sulfurCount: Int = 0
    var othersCount: Int = 0

    var totalCount: Int {
        return carbonCount + nitrogenCount + hydrogenCount + oxygenCount + sulfurCount + othersCount
    }
    
    static func +=(left: inout AtomArrayComposition, right: AtomArrayComposition) {
        left.carbonCount += right.carbonCount
        left.nitrogenCount += right.nitrogenCount
        left.hydrogenCount += right.hydrogenCount
        left.oxygenCount += right.oxygenCount
        left.sulfurCount += right.sulfurCount
        left.othersCount += right.othersCount
    }
    
    init() {
        
    }
    
    init(elements: [AtomElement]) {
        for element in elements {
            switch element {
            case .carbon:
                carbonCount += 1
            case .nitrogen:
                nitrogenCount += 1
            case .hydrogen:
                hydrogenCount += 1
            case .oxygen:
                oxygenCount += 1
            case .sulfur:
                sulfurCount += 1
            default:
                othersCount += 1
            }
        }
    }
}
