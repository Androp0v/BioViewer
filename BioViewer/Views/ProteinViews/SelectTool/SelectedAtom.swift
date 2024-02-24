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
        VStack(spacing: 0) {
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
                        .frame(maxWidth: .infinity)
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
                            .frame(width: 12, height: 12)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                )
                .foregroundColor(.primary)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 4)
            
            switch selectionModel.selectionOption {
            case .debug:
                SelectedDebugView()
            case .element:
                SelectedElementView()
            case .chain:
                EmptyView()
            case .residue:
                EmptyView()
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
