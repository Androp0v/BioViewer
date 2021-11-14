//
//  LoadingProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

/// Struct holding the contents of a protein.
public class Protein {

    // MARK: - State

    /// States reflect wether or not the protein has been added to a scene.
    public enum LoadState {
        case loading
        case loaded
        case failed
    }
    private(set) var state: LoadState
    
    // MARK: - File properties
    public var fileInfo: ProteinFileInfo

    // MARK: - Sequence

    /// Total number of residues in the protein sequence.
    public var resCount: Int?

    // Sequence (i.e. ["ALA", "GLC", "TRY"])
    private var sequence: [String]?

    // MARK: - Atoms

    /// Number of atoms in the protein.
    public var atomCount: Int

    /// Atomic positions (in Armstrongs). ContiguousArray is faster than array since we
    /// don't need to add new atoms after its creation. Also has easier conversion to MTLBuffer.
    ///
    /// Stored in C,N,H,O,S,X order (X for others).
    public var atoms: ContiguousArray<simd_float3>

    /// Number of atoms of each element.
    public var atomArrayComposition: AtomArrayComposition

    /// Atom identifiers (C,N,H,O,S...) mapped to int values.
    public var atomIdentifiers: [UInt8]

    /// Index of the last atom added to the scene (for .loading proteins).
    private var currentIndex: Int
    
    // MARK: - Initialization

    init(fileInfo: ProteinFileInfo, atoms: inout ContiguousArray<simd_float3>, atomArrayComposition: inout AtomArrayComposition, atomIdentifiers: [UInt8], sequence: [String]? = nil) {
        self.state = .loading
        self.fileInfo = fileInfo
        self.atoms = atoms
        self.atomArrayComposition = atomArrayComposition
        self.atomIdentifiers = atomIdentifiers
        self.atomCount = atoms.count
        self.currentIndex = 0
        self.sequence = sequence
        normalizeAtomPositions(atoms: &self.atoms)
    }

    // MARK: - Functions

    /// Return the atoms in the protein one by one until the protein is loaded
    /// - Returns: Atom position and atom identifier.
    func getNextAtom() -> (simd_float3?, UInt8?, Float?) {
        guard currentIndex < atomCount else {
            self.state = .failed
            return (nil, nil, nil)
        }
        let nextAtomPosition = self.atoms[self.currentIndex]
        let nextAtomId = self.atomIdentifiers[self.currentIndex]
        self.currentIndex += 1
        if currentIndex >= atomCount {
            self.state = .loaded
        }
        let percentLoaded = Float(currentIndex)/Float(atomCount)
        return (nextAtomPosition, nextAtomId, percentLoaded)
    }
}
