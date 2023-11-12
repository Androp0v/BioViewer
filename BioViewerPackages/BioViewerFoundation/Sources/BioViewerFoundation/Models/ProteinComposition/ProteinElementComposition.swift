//
//  ProteinElementComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import Foundation

public struct ProteinElementComposition {
    
    /// Dictionary containing the number of atoms of each type of element.
    public var elementCounts = [AtomElement: Int]()
    /// The total count of atoms of all types.
    public var totalCount: Int = 0
    /// The total count of atoms of a type present in `AtomElement.importantElements`.
    public var importantElementCount: Int {
        var sum: Int = 0
        for element in AtomElement.importantElements {
            sum += elementCounts[element] ?? 0
        }
        return sum
    }
    
    public static func += (lhs: inout ProteinElementComposition, rhs: ProteinElementComposition) {
        lhs.elementCounts.merge(rhs.elementCounts, uniquingKeysWith: { lhsCount, rhsCount in
            return lhsCount + rhsCount
        })
        lhs.totalCount += rhs.totalCount
    }
    
    // MARK: - Init
    
    public init() {}
    
    public init(elements: [AtomElement]) {
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
