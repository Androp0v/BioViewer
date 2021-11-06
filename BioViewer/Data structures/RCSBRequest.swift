//
//  RCSBRequest.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import Foundation
import SwiftUI

enum RCSBRequestType: String {
    case postRequest = "POST"
    case getRequest = "GET"
}

enum RCSBEndpoint: String {
    case getPDBInfo = "https://data.rcsb.org/rest/v1/core/entry/"
    case downloadPDBFile = "https://files.rcsb.org/download/"
    case downloadPDBImage = "https://cdn.rcsb.org/images/structures/" // og/2ogm/2ogm_assembly-1.jpeg
}

enum RCSBError: Error {
    case notFound
    case internalServerError
    case unknown
    case badImageData
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

/// Handles requests and queries to the RCSB database for PDB files
class RCSBFetch {
    static func fetchPDBInfo(rcsbid: String) async throws  -> PDBInfo {
        
        guard let url = URL(string: RCSBEndpoint.getPDBInfo.rawValue + rcsbid) else {
            fatalError()
        }
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            break
        case 404:
            throw RCSBError.notFound
        case 500:
            throw RCSBError.internalServerError
        default:
            throw RCSBError.unknown
        }
        
        let pdbInfo = try JSONDecoder().decode(PDBInfo.self, from: data)
        return pdbInfo
    }
    
    static func fetchPDBFile(rcsbid: String) async throws -> String {
        
        guard let url = URL(string: RCSBEndpoint.downloadPDBFile.rawValue + rcsbid + ".pdb1") else {
            fatalError()
        }
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            break
        case 404:
            throw RCSBError.notFound
        case 500:
            throw RCSBError.internalServerError
        default:
            throw RCSBError.unknown
        }
                
        let rawText = String(decoding: data, as: UTF8.self)
        return rawText
    }
    
    static func fetchPDBImage(rcsbid: String) async throws -> Image? {
        // https://cdn.rcsb.org/images/structures/og/2ogm/2ogm_assembly-1.jpeg
        // https://cdn.rcsb.org/images/structures/OG/2OGM/2OGM_assembly-1.jpeg
        let imageDirectory = (rcsbid as NSString).substring(with: NSRange(location: 1, length: 2)).lowercased() + "/"
        guard let url = URL(string: RCSBEndpoint.downloadPDBImage.rawValue
                            + imageDirectory
                            + rcsbid.lowercased()
                            + "/" + rcsbid.lowercased() + "_assembly-1.jpeg") else {
            fatalError()
        }
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            break
        case 404:
            throw RCSBError.notFound
        case 500:
            throw RCSBError.internalServerError
        default:
            throw RCSBError.unknown
        }
        
        guard let uiImage = UIImage(data: data) else {
            throw RCSBError.badImageData
        }
        
        return Image(uiImage: uiImage)
    }
}
