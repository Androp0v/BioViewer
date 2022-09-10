//
//  InfoAtomsRow.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/3/22.
//

import SwiftUI

struct InfoAtomsRow: View {
    let label: String
    let value: Int
    let isDisabled: Bool
    let file: ProteinFile
    
    @State var buttonToggle: Bool = false
    @EnvironmentObject var proteinViewModel: ProteinViewModel

    var body: some View {
        
        HStack(spacing: 4) {
            
            VStack {
                HStack {
                    Text(label)
                    Text("\(value)")
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Spacer()
                }
                Spacer()
                    .frame(height: 8)
                // TO-DO:
                InfoAtomsCapsule(file: file)
                    .opacity(0.8)
                Spacer()
                    .frame(height: 4)
            }
            
            Spacer()
                        
            Button(action: {
                buttonToggle.toggle()
            },
                   label: {
                Image(systemName: "info.circle")
            })
                .foregroundColor(Color.accentColor)
                .buttonStyle(PlainButtonStyle())
                .disabled(isDisabled)
                .popover(isPresented: $buttonToggle) {
                    FileAtomElementPopover()
                        .environmentObject(proteinViewModel)
                }
        }
    }
}

/*
struct InfoAtomsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            InfoAtomsRow(label: "Número de átomos",
                         value: "58336",
                         isDisabled: false
                         file: ProteinFile())
        }
    }
}
*/
