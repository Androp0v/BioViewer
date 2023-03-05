//
//  LoadingProtein.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/5/21.
//

import Foundation
import simd

/// Class holding the contents of a protein.
class Protein {

    // MARK: - UUID
    
    /// Internal-use unique identifier.
    var id = UUID()

    // MARK: - Sequence

    /// Total number of residues in the protein sequence.
    var resCount: Int?

    // Sequence (i.e. ["ALA", "GLC", "TRY"])
    private var sequence: [String]?
    
    // MARK: - Subunits
    
    /// Number of subunits in the protein
    var subunitCount: Int
    
    /// List of all subunits in the protein
    var subunits: [ProteinSubunit]?
    
    // MARK: - Atoms
    
    /// Number of atoms in the protein.
    var atomCount: Int

    /// Atomic positions (in Armstrongs). ContiguousArray is faster than array since we
    /// don't need to add new atoms after its creation. Also has easier conversion to MTLBuffer.
    ///
    /// Stored in C, H, N, O, S, X order (X for others).
    var atoms: ContiguousArray<simd_float3>

    /// Number of atoms of each element.
    var elementComposition: ProteinElementComposition
    
    /// Number of atoms of each kind.
    var residueComposition: ProteinResidueComposition?

    /// Atom identifiers (C,N,H,O,S...) mapped to int values.
    var atomElements: [AtomElement]
    
    /// Residue type of each atom.
    var atomResidues: [Residue]?
    
    /// Secondary structure of which each atom is part of.
    var atomSecondaryStructure: [SecondaryStructure]?
    
    // MARK: - Bonds
    
    /// Array with bond data for the structure.
    var bonds: [BondStruct]?
    
    // MARK: - Cartoon
    
    /// The cartoon structures of the protein (helices, sheets and loops).
    var cartoonStructures: [CartoonModel]?
    
    // MARK: - Configurations
    
    /// Number of configurations for this structure.
    var configurationCount: Int
    /// Number of bonds in each configuration.
    var bondsPerConfiguration: [Int]?
    /// Index of the bond array start  for each configuration.
    var bondsConfigurationArrayStart: [Int]?
    /// Energies of each configuration.
    var configurationEnergies: [Float]?
    
    // MARK: - Volume
    
    var boundingSphere: BoundingSphere
    
    // MARK: - Initialization

    init(
        configurationCount: Int,
        configurationEnergies: [Float]?,
        subunitCount: Int,
        subunits: [ProteinSubunit],
        atoms: ContiguousArray<simd_float3>,
        elementComposition: ProteinElementComposition,
        atomElements: [AtomElement],
        residueComposition: ProteinResidueComposition?,
        atomResidues: [Residue]?,
        atomSecondaryStructure: [SecondaryStructure]?,
        sequence: [String]? = nil
    ) {
        self.configurationCount = configurationCount
        self.configurationEnergies = configurationEnergies
        self.subunitCount = subunitCount
        self.subunits = subunits
        self.atoms = atoms
        self.elementComposition = elementComposition
        self.atomElements = atomElements
        self.residueComposition = residueComposition
        self.atomResidues = atomResidues
        self.atomSecondaryStructure = atomSecondaryStructure
        self.atomCount = elementComposition.totalCount
        self.sequence = sequence
        self.boundingSphere = computeBoundingSphere(atoms: atoms)
    }
}

// MARK: - Equatable

extension Protein: Equatable {
    static func == (lhs: Protein, rhs: Protein) -> Bool {
        return lhs.id == rhs.id
    }
}
