//
//  CIFConstants.swift
//
//
//  Created by Raúl Montón Pinillos on 22/2/24.
//

import Foundation

public enum Directives {
    static let loop = "loop_"
    static let comment = "#"
}
public enum CategoryNames {
    
    static let categoriesToSave: [String] = {
        var categoriesToSave = [String]()
        categoriesToSave.append(Entry.id)
        categoriesToSave.append(AtomSite.groupPDB)
        categoriesToSave.append(AtomSite.typeSymbol)
        categoriesToSave.append(AtomSite.compID)
        categoriesToSave.append(AtomSite.entityID)
        categoriesToSave.append(AtomSite.cartnX)
        categoriesToSave.append(AtomSite.cartnY)
        categoriesToSave.append(AtomSite.cartnZ)
        return categoriesToSave
    }()
    
    public enum Entry {
        static let id = "_entry.id"
    }
    public enum AtomSite {
        static let groupPDB = "_atom_site.group_PDB"
        static let typeSymbol = "_atom_site.type_symbol"
        static let compID = "_atom_site.label_comp_id"
        static let entityID = "_atom_site.label_entity_id"
        static let cartnX = "_atom_site.Cartn_x"
        static let cartnY = "_atom_site.Cartn_y"
        static let cartnZ = "_atom_site.Cartn_z"
    }
}
