//
//  ProteinExtensions.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/6/22.
//

import Foundation

extension Array where Element == Protein {
    var combinedAtomCount: Int {
        return reduce(0) { $0 + $1.atomCount }
    }
}
