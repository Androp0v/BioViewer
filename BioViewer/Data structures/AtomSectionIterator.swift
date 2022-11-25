//
//  AtomSectionIterator.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 22/5/21.
//

import Foundation

// MARK: - AtomSection

/// AtomSection struct retains information about an ```AtomArrayComposition```
/// array: the element, the starting index for that element (relative to the
/// ```AtomArrayComposition``` array) and the length of the section.
public struct AtomSection {
    // The atom element identifier
    var atomIdentifier: UInt16
    // The starting index for that element
    var startsAt: Int
    // The length of the section (number of atoms of that element)
    var length: Int
}

// MARK: - AtomSectionSequence

/// Use this class to safely iterate over all the ```AtomSection```s in an array of atoms
class AtomSectionSequence: Sequence {

    var atomArrayComposition: AtomArrayComposition

    /// The iterator gives the next ```AtomSection``` of a given ```AtomCompositionArray```
    /// from a ```Protein``` object.
    public struct AtomSectionIterator: IteratorProtocol {

        // The element the iterator returns
        typealias Element = AtomSection

        // Iterator properties to compute the next section
        var atomArrayComposition: AtomArrayComposition
        var currentSection: Int = 0
        var currentOffset: Int = 0

        /// Required ```IteratorProtocol``` method, returns the next element
        /// in the sequence, a ```AtomSection``` in this class.
        mutating func next() -> AtomSection? {
            var atomSection: AtomSection

            switch currentSection {
            case 0:
                atomSection = AtomSection(atomIdentifier: AtomType.CARBON,
                                          startsAt: currentOffset,
                                          length: atomArrayComposition.carbonCount)
                currentOffset += atomArrayComposition.carbonCount
            case 1:
                atomSection = AtomSection(atomIdentifier: AtomType.NITROGEN,
                                          startsAt: currentOffset,
                                          length: atomArrayComposition.nitrogenCount)
                currentOffset += atomArrayComposition.nitrogenCount
            case 2:
                atomSection = AtomSection(atomIdentifier: AtomType.HYDROGEN,
                                          startsAt: currentOffset,
                                          length: atomArrayComposition.hydrogenCount)
                currentOffset += atomArrayComposition.hydrogenCount
            case 3:
                atomSection = AtomSection(atomIdentifier: AtomType.OXYGEN,
                                          startsAt: currentOffset,
                                          length: atomArrayComposition.oxygenCount)
                currentOffset += atomArrayComposition.oxygenCount
            case 4:
                atomSection = AtomSection(atomIdentifier: AtomType.SULFUR,
                                          startsAt: currentOffset,
                                          length: atomArrayComposition.sulfurCount)
                currentOffset += atomArrayComposition.sulfurCount
            case 5:
                atomSection = AtomSection(atomIdentifier: AtomType.UNKNOWN,
                                          startsAt: currentOffset,
                                          length: atomArrayComposition.othersCount)
                currentOffset += atomArrayComposition.othersCount
            default:
                currentSection += 1
                return nil
            }
            currentSection += 1
            return atomSection
        }
    }

    init(protein: Protein) {
        self.atomArrayComposition = protein.atomArrayComposition
    }

    func makeIterator() -> AtomSectionIterator {
        return AtomSectionIterator(atomArrayComposition: self.atomArrayComposition)
    }
}
