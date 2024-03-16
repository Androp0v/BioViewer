//
//  SelectedElement.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 27/2/22.
//

import SwiftUI

struct SelectedAtom: View {
    
    @Environment(SelectionModel.self) var selectionModel: SelectionModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            @Bindable var bindableSelectionModel = selectionModel
            ZStack(alignment: .leading) {
                HStack(spacing: .zero) {
                    Text(NSLocalizedString("Selecting", comment: ""))
                        .bold()
                    #if !targetEnvironment(macCatalyst)
                    Spacer()
                        .frame(width: 8)
                    #endif
                    BioViewerPicker(selection: $bindableSelectionModel.selectionOption)
                }
                .padding(.horizontal, 24)
                .padding(.leading, 36)
                
                Button(
                    action: {
                        selectionModel.deselect()
                    },
                    label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            #if targetEnvironment(macCatalyst)
                            .frame(width: 12, height: 12)
                            #else
                            .frame(width: 16, height: 16)
                            #endif
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                )
                .foregroundColor(.primary)
                .buttonStyle(PlainButtonStyle())
            }
            #if targetEnvironment(macCatalyst)
            .padding(.vertical, 4)
            #else
            .padding(.vertical, 8)
            #endif
            
            switch selectionModel.selectionOption {
            #if DEBUG
            case .debug:
                SelectedDebugView()
            #endif
            case .element:
                SelectedElementView()
            case .chain:
                SelectedChainView()
            case .residue:
                SelectedResidueView()
            }
        }
        .background(.thinMaterial)
        .cornerRadius(12)
        .frame(maxWidth: 300, alignment: .bottomLeading)
        .padding()
        .transition(.move(edge: .bottom))
    }
}

struct SelectedElement_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black
                .ignoresSafeArea()
            SelectedAtom()
        }
    }
}
