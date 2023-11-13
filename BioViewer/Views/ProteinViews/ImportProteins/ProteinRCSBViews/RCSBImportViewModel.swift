//
//  RCSBImportViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import BioViewerFoundation
import Foundation
import SwiftUI

struct RCSBEntry {
    let image: Image?
    let name: String?
    let description: String?
    let authors: String?
}

@MainActor class RCSBImportViewModel: ObservableObject {
        
    @Published private(set) var results: [PDBInfo]?
    @Published var resultImages = [PDBInfo: Image]()
    @Published var isLoading: Bool = false
    
    struct OngoingSearch {
        let searchString: String
        let lastRow: Int
        let totalCount: Int
    }
    var currentSearch: OngoingSearch?
    
    func search(text: String) async throws {
        guard !text.isEmpty else {
            Task { @MainActor in
                currentSearch = nil
                withAnimation {
                    results = nil
                    resultImages = [:]
                }
            }
            return
        }
        let searchResult = try await RCSBFetch.search(text)
        Task { @MainActor in
            currentSearch = OngoingSearch(
                searchString: text,
                lastRow: 0,
                totalCount: searchResult.totalCount
            )
            withAnimation {
                results = searchResult.results
                resultImages = [:]
            }
        }
    }
    
    @MainActor func loadNextPageIfNeeded() {
        guard let currentSearch else { return }
        guard currentSearch.lastRow < (currentSearch.totalCount - 1) else { return }
        guard !isLoading else { return }
        withAnimation {
            isLoading = true
        }
        Task {
            let nextSearchPage = try await RCSBFetch.search(
                currentSearch.searchString,
                startRow: currentSearch.lastRow + 1
            )
            withAnimation {
                results?.append(contentsOf: nextSearchPage.results)
                isLoading = false
            }
            self.currentSearch = OngoingSearch(
                searchString: currentSearch.searchString,
                lastRow: nextSearchPage.results.count - 1,
                totalCount: currentSearch.totalCount
            )
        }
    }
    
    // MARK: - File download
    
    func fetchPDBFile(pdbInfo: PDBInfo, proteinDataSource: ProteinDataSource, statusViewModel: StatusViewModel) async throws {
        
        let importStatusAction = StatusAction(
            type: .importFile,
            description: NSLocalizedString("Downloading file", comment: ""),
            progress: nil
        )
        statusViewModel.showStatusForAction(importStatusAction)
        do {
            let (rawText, byteSize) = try await RCSBFetch.fetchPDBFile(rcsbid: pdbInfo.rcsbID)
            let fileInfo = ProteinFileInfo(
                pdbID: pdbInfo.rcsbID,
                description: pdbInfo.description,
                authors: pdbInfo.authors,
                sourceLines: nil
            )
            try? await FileImporter.importFileFromRawText(
                rawText: rawText,
                proteinDataSource: proteinDataSource,
                statusViewModel: statusViewModel, 
                statusAction: importStatusAction,
                fileInfo: fileInfo,
                fileName: pdbInfo.rcsbID,
                fileExtension: "pdb",
                byteSize: byteSize
            )
        } catch RCSBError.notFound {
            statusViewModel.signalActionFinished(importStatusAction, withError: ImportError.notFound)
        } catch {
            statusViewModel.signalActionFinished(importStatusAction, withError: ImportError.downloadError)
        }
    }
}
