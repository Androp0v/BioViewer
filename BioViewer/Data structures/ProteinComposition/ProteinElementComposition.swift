//
//  ProteinElementComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import Foundation

class ProteinElementComposition {
    
    var elementCounts = [AtomElement: Int]()

    var totalCount: Int {
        var sum: Int  = 0
        for elementCount in elementCounts.values {
            sum += elementCount
        }
        return sum
    }
    
    var importantElementCount: Int {
        var sum: Int = 0
        for element in AtomElement.importantElements {
            sum += elementCounts[element] ?? 0
        }
        return sum
    }
    
    static func +=(lhs: inout ProteinElementComposition, rhs: ProteinElementComposition) {
        lhs.elementCounts.merge(rhs.elementCounts, uniquingKeysWith: { lhsCount, rhsCount in
            return lhsCount + rhsCount
        })
    }
    
    init() {
        
    }
    
    init(elements: [AtomElement]) {
        for element in elements {
            if let currentCount = elementCounts[element] {
                elementCounts[element] = currentCount + 1
            } else {
                elementCounts[element] = 1
            }
        }
    }
}
