//
//  AtomArrayComposition.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/21.
//

import Foundation

public struct AtomArrayComposition {
    var carbonCount: Int = 0
    var nitrogenCount: Int = 0
    var hydrogenCount: Int = 0
    var oxygenCount: Int = 0
    var sulfurCount: Int = 0
    var othersCount: Int = 0

    var totalCount: Int {
        return carbonCount + nitrogenCount + hydrogenCount + oxygenCount + sulfurCount + othersCount
    }
}
