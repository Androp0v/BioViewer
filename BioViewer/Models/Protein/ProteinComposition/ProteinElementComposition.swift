//
//  ProteinElementComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import Foundation

struct ProteinElementComposition {
    
    /// Dictionary containing the number of atoms of each type of element.
    var elementCounts = [AtomElement: Int]()
    /// The total count of atoms of all types.
    var totalCount: Int = 0
    /// The total count of atoms of a type present in `AtomElement.importantElements`.
    var importantElementCount: Int {
        var sum: Int = 0
        for element in AtomElement.importantElements {
            sum += elementCounts[element] ?? 0
        }
        return sum
    }
    
    static func += (lhs: inout ProteinElementComposition, rhs: ProteinElementComposition) {
        lhs.elementCounts.merge(rhs.elementCounts, uniquingKeysWith: { lhsCount, rhsCount in
            return lhsCount + rhsCount
        })
        lhs.totalCount += rhs.totalCount
    }
    
    // MARK: - Init
    
    init() {}
    
    init(elements: [AtomElement]) {
        for element in elements {
            if let currentCount = elementCounts[element] {
                elementCounts[element] = currentCount + 1
            } else {
                elementCounts[element] = 1
            }
        }
        for elementCount in elementCounts.values {
            totalCount += elementCount
        }
    }
}
