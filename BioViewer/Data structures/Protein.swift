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
struct Protein {

    // MARK: - Properties

    // States reflect wether or not the protein has been added
    // to a SceneKit scene.
    public enum LoadState {
        case loading
        case loaded
        case failed
    }
    private(set) var state: LoadState

    // Atomic positions (in Armstrongs)
    private var atoms: [simd_float3]
    // Atom identifiers (C,H,F,O,N...) mapped to int values
    private var atomIdentifiers: [Int]
    // Total number of atoms in the protein
    private var atomCount: Int
    // Index of the last atom added to the scene (for .loading
    // proteins).
    private var currentIndex: Int

    // MARK: - Initialization

    init(atoms: [simd_float3], atomIdentifiers: [Int]) {
        self.state = .loading
        self.atoms = atoms
        self.atomIdentifiers = atomIdentifiers
        self.atomCount = atoms.count
        self.currentIndex = 0
        normalizeAtomPositions(atoms: &self.atoms)
    }

    // MARK: - Functions

    /// Return the atoms in the protein one by one until the protein is loaded
    /// - Returns: Atom position and atom identifier.
    mutating func getNextAtom() -> (simd_float3?, Int?) {
        guard currentIndex < atomCount else {
            self.state = .failed
            return (nil, nil)
        }
        let nextAtomPosition = self.atoms[self.currentIndex]
        let nextAtomId = self.atomIdentifiers[self.currentIndex]
        self.currentIndex += 1
        if currentIndex >= atomCount {
            self.state = .loaded
        }
        return (nextAtomPosition, nextAtomId)
    }
}
