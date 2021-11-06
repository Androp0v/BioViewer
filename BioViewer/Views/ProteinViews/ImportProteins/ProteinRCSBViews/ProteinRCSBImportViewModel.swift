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
    
    func fetchPDBInfo(rcsbid: String) async throws {
        guard !rcsbid.isEmpty else {
            withAnimation {
                showRow = false
            }
            return
        }
        
        guard let url = URL(string: RCSBEndpoint.getPDBInfo.rawValue + rcsbid) else {
            fatalError()
        }
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            break
        case 404:
            // TO-DO: Handle RCSB ID not found
            print("Not found")
            return
        default:
            return
        }
        
        let pdbInfo = try JSONDecoder().decode(PDBInfo.self, from: data)
        
        DispatchQueue.main.async {
            self.foundProteinName = pdbInfo.entry.id
            self.foundProteinDescription = pdbInfo.struct.title + "."
            
            withAnimation {
                self.showRow = true
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
        
        guard let url = URL(string: RCSBEndpoint.downloadPDBFile.rawValue + rcsbid + ".pdb1") else {
            fatalError()
        }
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200:
            break
        case 404:
            // TO-DO: Handle RCSB ID not found
            print("Not found")
            return
        default:
            return
        }
                
        DispatchQueue.global(qos: .userInitiated).async {
            proteinViewModel.statusUpdate(statusText: NSLocalizedString("Importing files", comment: ""))
            let rawText = String(decoding: data, as: UTF8.self)
            var protein = parsePDB(rawText: rawText, proteinViewModel: proteinViewModel)
            proteinViewModel.dataSource.addProteinToDataSource(protein: &protein, addToScene: true)
        }
    }
    
}
