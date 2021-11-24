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
    
    /// Number of subunits in the protein
    public var subunitCount: Int
    
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
    
    // MARK: - Initialization

    init(fileInfo: ProteinFileInfo, subunitCount: Int, atoms: inout ContiguousArray<simd_float3>, atomArrayComposition: inout AtomArrayComposition, atomIdentifiers: [UInt8], sequence: [String]? = nil) {
        self.state = .loading
        self.fileInfo = fileInfo
        self.subunitCount = subunitCount
        self.atoms = atoms
        self.atomArrayComposition = atomArrayComposition
        self.atomIdentifiers = atomIdentifiers
        self.atomCount = atoms.count
        self.sequence = sequence
        normalizeAtomPositions(atoms: &self.atoms)
    }
}
