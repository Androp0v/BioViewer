//
//  LoadingProtein.swift
//  PDB Viewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

/// Struct holding the contents of a protein that has not yet been completely loadad
/// into SceneKit.
struct LoadingProtein {

    public enum LoadState {
        case loading
        case loaded
        case failed
    }

    private(set) var state: LoadState
    private var atoms: [simd_float3]
    private var atomIdentifiers: [Int]
    private var atomCount: Int
    private var currentIndex: Int

    init(atoms: [simd_float3], atomIdentifiers: [Int]) {
        self.state = .loading
        self.atoms = atoms
        self.atomIdentifiers = atomIdentifiers
        self.atomCount = atoms.count
        self.currentIndex = 0
        normalizeAtomPositions(atoms: &self.atoms)
    }

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
