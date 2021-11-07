//
//  ProteinRCSBImportViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import Foundation
import SwiftUI

class ProteinRCSBImportViewModel: ObservableObject {
    
    @Published var showRow: Bool = false
    @Published var foundProteinImage: Image?
    @Published var foundProteinName: String?
    @Published var foundProteinDescription: String?
    
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
                withAnimation {
                    self.foundProteinName = pdbInfo.entry.id
                    self.foundProteinDescription = pdbInfo.struct.title + "."
                    self.showRow = true
                }
            }
        } catch {
            
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
        
        DispatchQueue.main.async {
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
                    var protein = try parsePDB(rawText: rawText, proteinViewModel: proteinViewModel)
                    proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
                } catch PDBParsingError.emptyAtomCount {
                    proteinViewModel.statusFinished(withError: NSLocalizedString("Error: No ATOM data found in file", comment: ""))
                } catch {
                    proteinViewModel.statusFinished(withError: NSLocalizedString("Error importing file", comment: ""))
                }
            }
            
        } catch RCSBError.notFound {
            proteinViewModel.statusFinished(withError: NSLocalizedString("Error: PDB file not found", comment: ""))
        } catch {
            proteinViewModel.statusFinished(withError: NSLocalizedString("Error downloading file", comment: ""))
        }
    }
    
}
