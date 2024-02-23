//
//  ProteinChainComposition.swift
//
//
//  Created by Raúl Montón Pinillos on 23/2/24.
//

import Foundation

public struct ProteinChainComposition: Sendable {
    
    public var uniqueChainIDs = [ChainID]()
    /// Dictionary containing the number of atoms of each chain.
    public var chainIDCounts = [ChainID: Int]()
    /// The total count of atoms of all chains.
    public var totalCount: Int = 0
    
    // MARK: - Init
    
    public init() {}
    
    public init?(chainIDs: [ChainID]?) {
        guard let chainIDs else { return nil }
        self = .init(chainIDs: chainIDs)
    }
    
    public init(chainIDs: [ChainID]) {
        for chainID in chainIDs {
            if let currentCount = chainIDCounts[chainID] {
                chainIDCounts[chainID] = currentCount + 1
            } else {
                chainIDCounts[chainID] = 1
                uniqueChainIDs.append(chainID)
            }
        }
        for atomsInChainID in chainIDCounts.values {
            totalCount += atomsInChainID
        }
    }
}
