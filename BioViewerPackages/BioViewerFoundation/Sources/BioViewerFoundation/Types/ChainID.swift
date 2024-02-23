//
//  ChainID.swift
//
//
//  Created by Raúl Montón Pinillos on 22/2/24.
//

import Foundation

public struct ChainID: Sendable, RawRepresentable, Hashable {
    public var rawValue: UInt16
    public typealias RawValue = UInt16
    
    public static let zero: ChainID = ChainID(privateRawValue: 0)
    public static let defaultMapping: [String: UInt16] = {
        let letterMapping: [String: UInt16] = [
            "A": 0,
            "B": 1,
            "C": 2,
            "D": 3,
            "E": 4,
            "F": 5,
            "G": 6,
            "H": 7,
            "I": 8,
            "J": 9,
            "K": 10,
            "L": 11,
            "M": 12,
            "N": 13,
            "O": 14,
            "P": 15,
            "Q": 16,
            "R": 17,
            "S": 18,
            "T": 19,
            "U": 20,
            "V": 21,
            "W": 22,
            "X": 23,
            "Y": 24,
            "Z": 25
        ]
        return letterMapping
    }()
    
    // MARK: - Init
    
    public init?(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    public init?(string: String) {
        if let rawValue = Self.defaultMapping[string] {
            self = .init(privateRawValue: rawValue)
        } else {
            return nil
        }
    }
    
    private init(privateRawValue: UInt16) {
        self.rawValue = privateRawValue
    }
    
    // MARK: - Computed
    
    public var displayName: String {
        let letters = [
            "A",
            "B",
            "C",
            "D",
            "E",
            "F",
            "G",
            "H",
            "I",
            "J",
            "K",
            "L",
            "M",
            "N",
            "O",
            "P",
            "Q",
            "R",
            "S",
            "T",
            "U",
            "V",
            "W",
            "X",
            "Y",
            "Z"
        ]
        
        if rawValue < 26 {
            return "Chain \(letters[Int(rawValue)])"
        } else {
            return "Chain \(rawValue)"
        }
    }
}
