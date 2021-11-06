//
//  RCSBRequest.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import Foundation

enum RCSBRequestType: String {
    case postRequest = "POST"
    case getRequest = "GET"
}

enum RCSBEndpoint: String {
    case getPDBInfo = "https://data.rcsb.org/rest/v1/core/entry/"
    case downloadPDBFile = "https://files.rcsb.org/download/"
}

struct PDBInfo: Decodable {
    let entry: Entry
    let `struct`: Struct
    
    struct Entry: Decodable {
        let id: String
    }
    
    struct Struct: Decodable {
        let pdbx_descriptor: String
        let title: String
    }
}
