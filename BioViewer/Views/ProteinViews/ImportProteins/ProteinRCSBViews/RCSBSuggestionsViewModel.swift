//
//  RCSBSuggestionsViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 1/12/21.
//

import Foundation
import SwiftUI
import simd

final class ProteinSuggestionRowData: Decodable, Hashable {
    
    let rcsbid: String
    let description: String
    let authors: String
    
    var pdbImage: Image?
    
    static func == (lhs: ProteinSuggestionRowData, rhs: ProteinSuggestionRowData) -> Bool {
        if lhs.rcsbid != rhs.rcsbid ||
            lhs.description != rhs.description ||
            lhs.authors != rhs.authors {
            return false
        }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rcsbid)
        hasher.combine(description)
        hasher.combine(authors)
    }
    
    enum CodingKeys: String, CodingKey {
        case rcsbid, description, authors
    }
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rcsbid = try container.decode(String.self, forKey: .rcsbid)
        description = try container.decode(String.self, forKey: .description)
        authors = try container.decode(String.self, forKey: .authors)
    }
}

struct ProteinSuggestionSectionData: Decodable, Hashable {
    static func == (lhs: ProteinSuggestionSectionData, rhs: ProteinSuggestionSectionData) -> Bool {
        if lhs.sectionTitle != rhs.sectionTitle ||
            lhs.sectionDescription != rhs.sectionDescription ||
            lhs.rowData != rhs.rowData {
            return false
        }
        return true
    }
    
    let sectionTitle: String
    let sectionDescription: String
    let rowData: [ProteinSuggestionRowData]
}

struct ProteinSuggestionData: Decodable {
    let sections: [ProteinSuggestionSectionData]?
}

@MainActor class RCSBSuggestionViewModel: ObservableObject {
    
    @Published var suggestionData: ProteinSuggestionData?
    
    init() {
        guard let proteinSuggestionJSON = Bundle.main.url(forResource: "RCSBSuggestionData", withExtension: "json") else {
            NSLog("Unable to find JSON with RCSB suggested structures.")
            return
        }
        guard let rawSuggestionData = try? Data(contentsOf: proteinSuggestionJSON) else {
            NSLog("Unable to parse JSON with RCSB suggested structures.")
            return
        }
        do {
            self.suggestionData = try JSONDecoder().decode(ProteinSuggestionData.self, from: rawSuggestionData)
        } catch {
            NSLog("Unable to parse JSON with RCSB suggested structures.")
        }
        
        Task {
            await loadImages()
        }
    }
    
    private func loadImages() async {
        await withTaskGroup(of: Void.self) { group in
            suggestionData?.sections?.forEach { section in
                section.rowData.forEach { row in
                    guard row.pdbImage == nil else { return }
                    group.addTask {
                        row.pdbImage = try? await RCSBFetch.fetchPDBImage(rcsbid: row.rcsbid)
                        return
                    }
                }
            }
        }
    }
}
