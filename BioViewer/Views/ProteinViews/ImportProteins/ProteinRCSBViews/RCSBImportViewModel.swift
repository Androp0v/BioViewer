//
//  RCSBImportViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import Foundation
import SwiftUI

class RCSBImportViewModel: ObservableObject {
    
    @Published private(set) var showRow: Bool = false
    @Published private(set) var foundProteinImage: Image?
    @Published private(set) var foundProteinName: String?
    @Published private(set) var foundProteinDescription: String?
    @Published private(set) var foundProteinAuthors: String?
    
    func getPDBInfo(rcsbid: String) async throws {
        guard !rcsbid.isEmpty else {
            withAnimation {
                showRow = false
            }
            return
        }
        
        do {
            let pdbInfo = try await RCSBFetch.fetchPDBInfo(rcsbid: rcsbid)
            DispatchQueue.main.sync {
                self.objectWillChange.send()
                self.showRow = true
                self.foundProteinName = pdbInfo.entry.id
                self.foundProteinDescription = pdbInfo.struct.title + "."
                self.foundProteinAuthors = pdbInfo.audit_author.map { $0.name }.joined(separator: ", ")
            }
        } catch let error {
            throw error
        }
    }
    
    func getPDBImage(rcsbid: String) async throws {
        guard !rcsbid.isEmpty else {
            withAnimation {
                showRow = false
            }
            return
        }
        
        let pdbImage = try await RCSBFetch.fetchPDBImage(rcsbid: rcsbid)
        DispatchQueue.main.sync {
            withAnimation {
                self.foundProteinImage = pdbImage
            }
        }
    }
    
    func fetchPDBFile(rcsbid: String, proteinViewModel: ProteinViewModel) async throws {
        guard !rcsbid.isEmpty else {
            withAnimation {
                showRow = false
            }
            return
        }
        
        proteinViewModel.statusUpdate(statusText: NSLocalizedString("Downloading file", comment: ""))
        
        do {
            let rawText = try await RCSBFetch.fetchPDBFile(rcsbid: rcsbid)
            
            DispatchQueue.global(qos: .userInitiated).async {
                proteinViewModel.statusUpdate(statusText: NSLocalizedString("Importing file", comment: ""))
                do {
                    let fileInfo = ProteinFileInfo(pdbID: self.foundProteinName,
                                                   description: self.foundProteinDescription,
                                                   authors: self.foundProteinAuthors,
                                                   sourceLines: nil)
                    var protein = try FileParser().parseTextFile(rawText: rawText,
                                                                 fileExtension: "pdb",
                                                                 fileInfo: fileInfo,
                                                                 proteinViewModel: proteinViewModel)
                    proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
                } catch let error as ImportError {
                    proteinViewModel.statusFinished(importError: error)
                } catch {
                    proteinViewModel.statusFinished(importError: ImportError.unknownError)
                }
            }
            
        } catch RCSBError.notFound {
            proteinViewModel.statusFinished(importError: ImportError.notFound)
        } catch {
            proteinViewModel.statusFinished(importError: ImportError.downloadError)
        }
    }
    
}
