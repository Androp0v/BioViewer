//
//  RCSBRequest.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import Foundation
import SwiftUI

// MARK: - RequestType

enum RCSBRequestType: String {
    case postRequest = "POST"
    case getRequest = "GET"
}

// MARK: - Endpoint
enum RCSBEndpoint: String {
    case search = "https://search.rcsb.org/rcsbsearch/v2/query"
    case getPDBInfo = "https://data.rcsb.org/rest/v1/core/entry/"
    case downloadPDBFile = "https://files.rcsb.org/download/"
    case downloadPDBImage = "https://cdn.rcsb.org/images/structures/"
}

// MARK: - RCSBInfo

struct RCSBAuthor: Decodable {
    let name: String
    let pdbx_ordinal: Int
}

struct RCSBInfo: Decodable {
    let audit_author: [RCSBAuthor]
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

struct PDBInfo: Identifiable, Hashable {
    let id: UUID
    let rcsbID: String
    let title: String
    let description: String
    let authors: String
    
    init(rcsbInfo: RCSBInfo) {
        self.id = UUID()
        self.rcsbID = rcsbInfo.entry.id
        self.title = rcsbInfo.struct.title
        self.description = rcsbInfo.struct.pdbx_descriptor
        self.authors = rcsbInfo.audit_author.map { $0.name }.joined(separator: ", ")
    }
    
    init(suggestion: ProteinSuggestionRowData) {
        self.id = UUID()
        self.rcsbID = suggestion.rcsbid
        self.title = ""
        self.description = suggestion.description
        self.authors = suggestion.authors
    }
}

// MARK: - SearchInput

struct RCSBSearchQuery: Encodable {
    let type: String = "terminal"
    let service: String = "full_text"
    let parameters: RCSBSearchParameters
    
    struct RCSBSearchParameters: Encodable {
        let value: String
    }
    
    init(searchText: String) {
        self.parameters = RCSBSearchParameters(value: searchText)
    }
}

struct RCSBSearchInput: Encodable {
    let query: RCSBSearchQuery
    let return_type: String = "entry"
    
    init(searchText: String) {
        self.query = RCSBSearchQuery(searchText: searchText)
    }
}

struct RCSBSearchResult: Decodable {
    let identifier: String
    let score: Double
}

struct RCSBSearchResults: Decodable {
    let result_set: [RCSBSearchResult]
}

// MARK: - Fetch

/// Handles requests and queries to the RCSB database for PDB files
class RCSBFetch {
    
    static func search(_ text: String) async throws -> [PDBInfo] {
        
        guard !text.isEmpty else { return [] }
        
        let searchInput = RCSBSearchInput(searchText: text)
        let jsonData = try JSONEncoder().encode(searchInput)
        let jsonString = String(data: jsonData, encoding: .utf8)
        guard let parameterString = jsonString?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw RCSBError.malformedInput
        }
        guard let url = URL(string: RCSBEndpoint.search.rawValue + "?json=\(parameterString)") else {
            throw RCSBError.malformedURL
        }
        
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            break
        case 204:
            return []
        case 404:
            throw RCSBError.notFound
        case 500:
            throw RCSBError.internalServerError
        default:
            throw RCSBError.unknown
        }
        
        let searchResults = try JSONDecoder().decode(RCSBSearchResults.self, from: data).result_set
        
        let pdbInfoResults = await withTaskGroup(of: RCSBInfo?.self, body: { group in
            var tempResults = [PDBInfo]()
            for result in searchResults {
                group.addTask {
                    return try? await fetchPDBInfo(rcsbid: result.identifier)
                }
            }
            for await rcsbResult in group {
                if let rcsbResult {
                    tempResults.append(PDBInfo(rcsbInfo: rcsbResult))
                }
            }
            return tempResults
        })
        
        // Sort by score
        let sortedResults = searchResults.sorted { $0.score > $1.score }
        var pdbInfoSorted = [PDBInfo]()
        for sortedResult in sortedResults {
            if let pdbInfoForID = pdbInfoResults.first(where: {$0.rcsbID == sortedResult.identifier}) {
                pdbInfoSorted.append(pdbInfoForID)
            }
        }
        
        return pdbInfoSorted
    }
    
    // MARK: - Info
    
    static func fetchPDBInfo(rcsbid: String) async throws  -> RCSBInfo {
        
        let rcsbid = rcsbid.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: RCSBEndpoint.getPDBInfo.rawValue + rcsbid) else {
            throw RCSBError.malformedURL
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
        
        let pdbInfo = try JSONDecoder().decode(RCSBInfo.self, from: data)
        return pdbInfo
    }
    
    // MARK: - File
    
    static func fetchPDBFile(rcsbid: String) async throws -> (String, Int) {
        
        guard let url = URL(string: RCSBEndpoint.downloadPDBFile.rawValue + rcsbid + ".pdb1") else {
            throw RCSBError.malformedURL
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
        let byteSize = (data as NSData).length
        
        return (rawText, byteSize)
    }
    
    // MARK: - Image
    
    static func fetchPDBImage(rcsbid: String) async throws -> Image? {
        guard rcsbid.count >= 4 else {
            throw RCSBError.invalidID
        }
        let imageDirectory = (rcsbid as NSString).substring(with: NSRange(location: 1, length: 2)).lowercased() + "/"
        guard let url = URL(
            string: RCSBEndpoint.downloadPDBImage.rawValue
                    + imageDirectory
                    + rcsbid.lowercased()
                    + "/" + rcsbid.lowercased()
                    + "_assembly-1.jpeg"
        ) else {
            throw RCSBError.malformedURL
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
