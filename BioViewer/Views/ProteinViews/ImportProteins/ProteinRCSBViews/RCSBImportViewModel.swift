//
//  RCSBImportViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import Foundation
import SwiftUI

struct RCSBEntry {
    let image: Image?
    let name: String?
    let description: String?
    let authors: String?
}

class RCSBImportViewModel: ObservableObject {
        
    @Published private(set) var results: [PDBInfo]?
    @Published var resultImages = [PDBInfo: Image]()
    
    func search(text: String) async throws {
        let searchResult = try await RCSBFetch.search(text)
        Task { @MainActor in
            withAnimation {
                results = searchResult
                resultImages = [:]
            }
        }
    }
    
    // MARK: - File download
    
    func fetchPDBFile(pdbInfo: PDBInfo, proteinViewModel: ProteinViewModel) async throws {
        
        proteinViewModel.statusUpdate(statusText: NSLocalizedString("Downloading file", comment: ""))
        do {
            let (rawText, byteSize) = try await RCSBFetch.fetchPDBFile(rcsbid: pdbInfo.rcsbID)
            DispatchQueue.global(qos: .userInitiated).async {
                let fileInfo = ProteinFileInfo(
                    pdbID: pdbInfo.rcsbID,
                    description: pdbInfo.description,
                    authors: pdbInfo.authors,
                    sourceLines: nil
                )
                try? FileImporter.importFileFromRawText(
                    rawText: rawText,
                    proteinViewModel: proteinViewModel,
                    fileInfo: fileInfo,
                    fileName: pdbInfo.rcsbID,
                    fileExtension: "pdb",
                    byteSize: byteSize
                )
            }
        } catch RCSBError.notFound {
            proteinViewModel.statusFinished(importError: ImportError.notFound)
        } catch {
            proteinViewModel.statusFinished(importError: ImportError.downloadError)
        }
    }
    
}
