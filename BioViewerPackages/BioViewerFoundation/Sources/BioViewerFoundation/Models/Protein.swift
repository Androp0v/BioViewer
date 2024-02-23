//
//  Protein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

/// Class holding the contents of a protein.
public struct Protein: Sendable {

    // MARK: - UUID
    
    /// Internal-use unique identifier.
    public let id = UUID()

    // MARK: - Sequence

    // Sequence (i.e. ["ALA", "GLC", "TRY"])
    public let sequence: [Residue]?
        
    // MARK: - Atoms
    
    /// Number of atoms in the protein.
    public let atomCount: Int

    /// Atomic positions (in Armstrongs). ContiguousArray is faster than array since we
    /// don't need to add new atoms after its creation. Also has easier conversion to MTLBuffer.
    public let atoms: ContiguousArray<simd_float3>

    /// Number of atoms of each element.
    public let elementComposition: ProteinElementComposition
    
    /// Number of atoms of each residue type.
    public let residueComposition: ProteinResidueComposition?

    /// Atom identifiers (C,N,H,O,S...) mapped to int values.
    public let atomElements: [AtomElement]
    
    /// Chain ID for each atom.
    public let atomChainIDs: [ChainID]?
    
    /// Residue type of each atom.
    public let atomResidues: [Residue]?
    
    /// Secondary structure of which each atom is part of.
    public let atomSecondaryStructure: [SecondaryStructure]?
    
    // MARK: - Chains
    
    /// Number of atoms of each chain.
    public let chainComposition: ProteinChainComposition?
    
    /// The number of unique chains in the protein.
    public var chainCount: Int {
        guard let chainComposition else { return 1 }
        return chainComposition.uniqueChainIDs.count
    }
    
    // MARK: - Bonds
    
    /// Array with bond data for the structure.
    public var bonds: [BondStruct]?
    
    // MARK: - Configurations
    
    /// Number of configurations for this structure.
    public let configurationCount: Int
    /// Number of bonds in each configuration.
    public var bondsPerConfiguration: [Int]?
    /// Index of the bond array start  for each configuration.
    public var bondsConfigurationArrayStart: [Int]?
    /// Energies of each configuration.
    public var configurationEnergies: [Float]?
    
    // MARK: - Volume
    
    public let boundingVolume: BoundingVolume
    
    // MARK: - Initialization

    public init(
        configurationCount: Int,
        configurationEnergies: [Float]?,
        atoms: ContiguousArray<simd_float3>,
        elementComposition: ProteinElementComposition,
        atomElements: [AtomElement],
        chainComposition: ProteinChainComposition?,
        atomChainIDs: [ChainID]?,
        residueComposition: ProteinResidueComposition?,
        atomResidues: [Residue]?,
        atomSecondaryStructure: [SecondaryStructure]?,
        sequence: [Residue]? = nil
    ) {
        self.configurationCount = configurationCount
        self.configurationEnergies = configurationEnergies
        self.atoms = atoms
        self.atomCount = elementComposition.totalCount
        
        self.elementComposition = elementComposition
        self.atomElements = atomElements
        
        self.chainComposition = chainComposition
        self.atomChainIDs = atomChainIDs
        
        self.residueComposition = residueComposition
        self.atomResidues = atomResidues
        
        self.atomSecondaryStructure = atomSecondaryStructure
        
        self.sequence = sequence
        self.boundingVolume = computeBoundingVolume(atoms: atoms)
    }
}

// MARK: - Extensions

extension Protein: Equatable {
    public static func == (lhs: Protein, rhs: Protein) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Array where Element == Protein {
    var combinedAtomCount: Int {
        return reduce(0) { $0 + $1.atomCount }
    }
}
