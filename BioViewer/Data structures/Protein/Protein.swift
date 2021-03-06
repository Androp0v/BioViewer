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

    // MARK: - Sequence

    /// Total number of residues in the protein sequence.
    public var resCount: Int?

    // Sequence (i.e. ["ALA", "GLC", "TRY"])
    private var sequence: [String]?
    
    // MARK: - Subunits
    
    /// Number of subunits in the protein
    public var subunitCount: Int
    
    /// List of all subunits in the protein
    public var subunits: [ProteinSubunit]?
    
    /// Whether the last subunit is just a collection of non-chain atoms.
    public var hasNonChainSubunit: Bool

    // MARK: - Atoms
    
    /// Number of atoms in the protein.
    public var atomCount: Int

    /// Atomic positions (in Armstrongs). ContiguousArray is faster than array since we
    /// don't need to add new atoms after its creation. Also has easier conversion to MTLBuffer.
    ///
    /// Stored in C, H, N, O, S, X order (X for others).
    public var atoms: ContiguousArray<simd_float3>

    /// Number of atoms of each element.
    public var atomArrayComposition: AtomArrayComposition

    /// Atom identifiers (C,N,H,O,S...) mapped to int values.
    public var atomIdentifiers: [UInt8]
    
    // MARK: - Bonds
    
    /// Array with bond data for the structure.
    public var bonds: [BondStruct]?
    
    // MARK: - Configurations
    
    /// Number of configurations for this structure.
    public var configurationCount: Int
    /// Number of bonds in each configuration.
    public var bondsPerConfiguration: [Int]?
    /// Index of the bond array start  for each configuration.
    public var bondsConfigurationArrayStart: [Int]?
    /// Energies of each configuration.
    public var configurationEnergies: [Float]?
    
    // MARK: - Volume
    
    public var boundingSphere: BoundingSphere
    
    // MARK: - Initialization

    init(configurationCount: Int, configurationEnergies: [Float]?, subunitCount: Int, subunits: [ProteinSubunit], hasNonChainSubunit: Bool, atoms: inout ContiguousArray<simd_float3>, atomArrayComposition: inout AtomArrayComposition, atomIdentifiers: [UInt8], sequence: [String]? = nil) {
        self.configurationCount = configurationCount
        self.configurationEnergies = configurationEnergies
        self.subunitCount = subunitCount
        self.subunits = subunits
        self.hasNonChainSubunit = hasNonChainSubunit
        self.atoms = atoms
        self.atomArrayComposition = atomArrayComposition
        self.atomIdentifiers = atomIdentifiers
        self.atomCount = atomArrayComposition.totalCount
        self.sequence = sequence
        self.boundingSphere = computeBoundingSphere(atoms: atoms)
        normalizeAtomPositions(atoms: &self.atoms, center: boundingSphere.center)
    }
}
