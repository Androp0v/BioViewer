//
//  WorkspaceRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

struct WorkspaceRow: View {
    
    @State var showWorkspaceHelp: Bool = false
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let iconSize: CGFloat = 16
        #else
        static let iconSize: CGFloat = 18
        #endif
    }

    var body: some View {
        HStack {
            
            Button(action: {
                WorkspaceExporter.createWorkspace(proteinViewModel: proteinViewModel)
            }, label: {
                Image(systemName: "square.and.arrow.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
            })
                .foregroundColor(.accentColor)
                .buttonStyle(PlainButtonStyle())
            
            Text(NSLocalizedString("Save as BioViewer workspace...", comment: ""))
            
            Spacer()
            
            Button(action: {
                showWorkspaceHelp.toggle()
            }, label: {
                Image(systemName: "questionmark.circle")
            })
                .foregroundColor(.accentColor)
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showWorkspaceHelp) {
                    WorkspaceHelp()
                }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews
struct WorkspaceRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            WorkspaceRow()
        }
        .frame(width: 300)
    }
}
