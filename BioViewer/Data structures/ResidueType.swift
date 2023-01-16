//
//  ResidueType.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/1/23.
//

import Foundation

enum Residue: UInt8 {
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
        }
    }
    
    init?(string: String) {
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
        default: return nil
        }
    }
}
