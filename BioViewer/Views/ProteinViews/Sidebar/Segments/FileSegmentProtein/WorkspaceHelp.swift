//
//  WorkspaceHelp.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/12/21.
//

import SwiftUI

#if os(iOS)
struct WorkspaceHelp: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text(NSLocalizedString("What are BioViewer workspaces?", comment: ""))
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(".bioviewer")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.accentColor)
                    .padding(12)
                Text(NSLocalizedString("bioViewer_workspace_description", comment: ""))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle(NSLocalizedString("Help", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(NSLocalizedString("Close", comment: "")) {
                dismiss()
            })
        }
    }
}

struct WorkspaceHelp_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceHelp()
    }
}
#endif
