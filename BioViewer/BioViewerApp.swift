//
//  PDB_ViewerApp.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 4/5/21.
//

import SwiftUI

@main
struct BioViewerApp: App {
        
    var body: some Scene {
                
        WindowGroup {
            MainView()
        }
        .commands {
            BioViewerCommands()
        }
    }
}
