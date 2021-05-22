//
//  LoadingProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

/// Struct holding the contents of a protein that has not yet been completely loadad
/// into SceneKit.
public struct Protein {

    // MARK: - State

    // States reflect wether or not the protein has been added
    // to a SceneKit scene.
    public enum LoadState {
        case loading
        case loaded
        case failed
    }
    private(set) var state: LoadState

    // MARK: - Sequence

    // Total number of residues in the protein sequence
    public var resCount: Int?

    // Sequence
    private var sequence: [String]?

    // MARK: - Atoms

    // Total number of atoms in the protein
    public var atomCount: Int

    // Atomic positions (in Armstrongs)
    public var atoms: ContiguousArray<simd_float3>
    // Atom identifiers (C,H,F,O,N...) mapped to int values
    public var atomIdentifiers: [Int]
    // Index of the last atom added to the scene (for .loading
    // proteins).
    private var currentIndex: Int
    

    // MARK: - Initialization

    init(atoms: [simd_float3], atomIdentifiers: [Int], sequence: [String]? = nil) {
        self.state = .loading
        self.atoms = ContiguousArray<simd_float3>(atoms)
        self.atomIdentifiers = atomIdentifiers
        self.atomCount = atoms.count
        self.currentIndex = 0
        self.sequence = sequence
        normalizeAtomPositions(atoms: &self.atoms)
    }

    // MARK: - Functions

    /// Return the atoms in the protein one by one until the protein is loaded
    /// - Returns: Atom position and atom identifier.
    mutating func getNextAtom() -> (simd_float3?, Int?, Float?) {
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
