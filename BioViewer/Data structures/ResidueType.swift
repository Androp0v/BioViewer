//
//  ResidueType.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/1/23.
//

import Foundation
import SwiftUI

// swiftlint:disable all

enum Residue: UInt8, CaseIterable {
    
    // MARK: - Amino acids
    
    case Arg
    case His
    case Lys
    case Asp
    case Glu
    case Ser
    case Thr
    case Asn
    case Gln
    case Cys
    case Sec
    case Gly
    case Pro
    case Ala
    case Val
    case Ile
    case Leu
    case Met
    case Phe
    case Tyr
    case Trp
    
    // MARK: - Nucleobases (ribonucleic)
    
    case A
    case C
    case G
    case T
    case U
    case I
    
    // MARK: - Nucleobases (deoxyribonucleic)
    
    case DA
    case DC
    case DG
    case DT
    case DU
    case DI
    
    
    // MARK: - Other
    
    case unknown
    
    // MARK: - Computed properties
    
    enum ResidueKind: CaseIterable {
        case aminoAcid
        case rnaNucleobase
        case dnaNucleobase
        case unknown
    }
    
    var kind: ResidueKind {
        switch self {
        case .Arg, .His, .Lys, .Asp, .Glu, .Ser, .Thr, .Asn, .Gln, .Cys, .Sec, .Gly, .Pro, .Ala, .Val, .Ile, .Leu, .Met, .Phe, .Tyr, .Trp:
            return .aminoAcid
        case .A, .C, .G, .T, .U, .I:
            return .rnaNucleobase
        case .DA, .DC, .DG, .DT, .DU, .DI:
            return .dnaNucleobase
        case .unknown:
            return .unknown
        }
    }
    
    var name: String {
        switch self {
        case .Arg: return "Arginine"
        case .His: return "Histidine"
        case .Lys: return "Lysine"
        case .Asp: return "Aspartic Acid"
        case .Glu: return "Glutamic Acid"
        case .Ser: return "Serine"
        case .Thr: return "Threonine"
        case .Asn: return "Asparagine"
        case .Gln: return "Glutamine"
        case .Cys: return "Cysteine"
        case .Sec: return "Selenocysteine"
        case .Gly: return "Glycine"
        case .Pro: return "Proline"
        case .Ala: return "Alanine"
        case .Val: return "Valine"
        case .Ile: return "Isoleucine"
        case .Leu: return "Leucine"
        case .Met: return "Methionine"
        case .Phe: return "Phenylalanine"
        case .Tyr: return "Tyrosine"
        case .Trp: return "Tryptophan"
            
        case .A: return "Adenine (RNA)"
        case .C: return "Cytosine (RNA)"
        case .G: return "Guanine (RNA)"
        case .T: return "Thymine (RNA)"
        case .U: return "Uracil (RNA)"
        case .I: return "Inosine (RNA)"
            
        case .DA: return "Adenine (DNA)"
        case .DC: return "Cytosine (DNA)"
        case .DG: return "Guanine (DNA)"
        case .DT: return "Thymine (DNA)"
        case .DU: return "Uracil (DNA)"
        case .DI: return "Inosine (DNA)"
            
        case .unknown: return "Unknown"
        }
    }
    
    var defaultColor: Color {
        switch self {
        case .Arg: return Color(red: 0.015, green: 0.090, blue: 0.576)
        case .His: return Color(red: 0.525, green: 0.572, blue: 1.000)
        case .Lys: return Color(red: 0.333, green: 0.376, blue: 0.800)
        case .Asp: return Color(red: 0.705, green: 0.172, blue: 0.329)
        case .Glu: return Color(red: 0.474, green: 0.094, blue: 0.047)
        case .Ser: return Color(red: 0.992, green: 0.584, blue: 0.388)
        case .Thr: return Color(red: 0.796, green: 0.411, blue: 0.156)
        case .Asn: return Color(red: 0.996, green: 0.631, blue: 0.568)
        case .Gln: return Color(red: 0.992, green: 0.454, blue: 0.407)
        case .Cys: return Color(red: 1.000, green: 0.992, blue: 0.517)
        case .Sec: return Color(red: 1.000, green: 0.776, blue: 0.278)
        case .Gly: return Color(red: 0.900, green: 0.900, blue: 0.900)
        case .Pro: return Color(red: 0.407, green: 0.407, blue: 0.407)
        case .Ala: return Color(red: 0.784, green: 1.000, blue: 0.756)
        case .Val: return Color(red: 0.988, green: 0.717, blue: 1.000)
        case .Ile: return Color(red: 0.141, green: 0.368, blue: 0.098)
        case .Leu: return Color(red: 0.364, green: 0.458, blue: 0.352)
        case .Met: return Color(red: 0.815, green: 0.741, blue: 0.396)
        case .Phe: return Color(red: 0.407, green: 0.376, blue: 0.407)
        case .Tyr: return Color(red: 0.654, green: 0.549, blue: 0.396)
        case .Trp: return Color(red: 0.392, green: 0.349, blue: 0.098)
            
        case .A: return Color(red: 1.000, green: 0.309, blue: 1.000)
        case .C: return Color(red: 0.412, green: 1.000, blue: 0.225)
        case .G: return Color(red: 0.222, green: 0.348, blue: 1.000)
        case .T: return Color(red: 1.000, green: 0.534, blue: 0.202)
        case .U: return Color(red: 1.000, green: 0.325, blue: 0.287)
        case .I: return Color(red: 1.000, green: 1.000, blue: 1.000)
            
        case .DA: return Color(red: 1.000, green: 0.309, blue: 1.000)
        case .DC: return Color(red: 0.412, green: 1.000, blue: 0.225)
        case .DG: return Color(red: 0.222, green: 0.348, blue: 1.000)
        case .DT: return Color(red: 1.000, green: 0.534, blue: 0.202)
        case .DU: return Color(red: 1.000, green: 0.325, blue: 0.287)
        case .DI: return Color(red: 1.000, green: 1.000, blue: 1.000)
            
        case .unknown: return Color(red: 0.500, green: 0.500, blue: 0.500)
        }
    }
    
    init(string: String) {
        switch string {
        case "ARG": self = .Arg
        case "HIS": self = .His
        case "LYS": self = .Lys
        case "ASP": self = .Asp
        case "GLU": self = .Glu
        case "SER": self = .Ser
        case "THR": self = .Thr
        case "ASN": self = .Asn
        case "GLN": self = .Gln
        case "CYS": self = .Cys
        case "SEC": self = .Sec
        case "GLY": self = .Gly
        case "PRO": self = .Pro
        case "ALA": self = .Ala
        case "VAL": self = .Val
        case "ILE": self = .Ile
        case "LEU": self = .Leu
        case "MET": self = .Met
        case "PHE": self = .Phe
        case "TYR": self = .Tyr
        case "TRP": self = .Trp
        case "A": self = .A
        case "C": self = .C
        case "G": self = .G
        case "T": self = .T
        case "U": self = .U
        case "I": self = .I
        case "DA": self = .DA
        case "DC": self = .DC
        case "DG": self = .DG
        case "DT": self = .DT
        case "DU": self = .DU
        case "DI": self = .DI
        default: self = .unknown
        }
    }
}
