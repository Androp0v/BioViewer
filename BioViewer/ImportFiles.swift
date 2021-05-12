//
//  ImportFiles.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/5/21.
//

import Foundation
import simd

fileprivate enum PDBConstants {
    // Expected line length of a properly formatted PDB file
    // (hard to think of such a mythical creature).
    static let expectedLineLenght: Int = 78

    // Start and end of the x coordinate positions
    static let xPositionStart: Int = 30
    static let xPositionEnd: Int = 38

    // Start and end of the y coordinate positions
    static let yPositionStart: Int = 38
    static let yPositionEnd: Int = 46

    // Start and end of the z coordinate positions
    static let zPositionStart: Int = 46
    static let zPositionEnd: Int = 54

    // Start and end of the element name
    static let elementStart: Int = 76
    static let elementEnd: Int = 78
}

func parsePDB(rawText: String) -> ([simd_float3], [Int]) {

    var atomArray = [simd_float3]()
    var atomIdentifiers = [Int]()

    rawText.enumerateLines(invoking: { line, stop in
        // We're only interested in the lines that contain atom positions
        if line.starts(with: "ATOM") {

            // Check that the input line has the expected length (or more)
            // to avoid IndexOutOfRange exceptions.

            guard line.count >= PDBConstants.expectedLineLenght else {
                return
            }

            // Swift strings can't be indexed using Int and have to use Index
            // instead (since under the hood not all string characters are the
            // same length, due to Unicode and stuff).

            let startX = line.index(line.startIndex, offsetBy: PDBConstants.xPositionStart)
            let endX = line.index(line.startIndex, offsetBy: PDBConstants.xPositionEnd)
            let rangeX = startX..<endX

            let startY = line.index(line.startIndex, offsetBy: PDBConstants.yPositionStart)
            let endY = line.index(line.startIndex, offsetBy: PDBConstants.yPositionEnd)
            let rangeY = startY..<endY

            let startZ = line.index(line.startIndex, offsetBy: PDBConstants.zPositionStart)
            let endZ = line.index(line.startIndex, offsetBy: PDBConstants.zPositionEnd)
            let rangeZ = startZ..<endZ

            // Check that all 3 coordinates are non-nil so we don't end up
            // with atoms with partial coordinates. Remove whitespaces too
            // or float-casting will return nil.

            guard let x = Float( line[rangeX].replacingOccurrences(of: " ", with: "") ),
                  let y = Float( line[rangeY].replacingOccurrences(of: " ", with: "") ),
                  let z = Float( line[rangeZ].replacingOccurrences(of: " ", with: "") )
            else {
                return
            }

            // Save atom position to array

            atomArray.append(simd_float3(x,y,z))

            // Retrieve atom element next

            let startElement = line.index(line.startIndex, offsetBy: PDBConstants.elementStart)
            let endElement = line.index(line.startIndex, offsetBy: PDBConstants.elementEnd)
            let rangeElement = startElement..<endElement

            let element = line[rangeElement].replacingOccurrences(of: " ", with: "")

            // Save atom element to array, might be of "UNKNOWN" type

            atomIdentifiers.append( getAtomId(atomName: String(element)) )
        }
    })
    return (atomArray, atomIdentifiers)
}

// MARK: - Private functions
fileprivate func getCleanSubstring(start: Int, end: Int, removeWhitespace: Bool = true) -> String {
    // TO-DO
    return ""
}
