//
//  ProteinRCSBImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct ProteinRCSBImportView: View {
    
    enum FocusField: Hashable {
        case field
      }
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @FocusState private var focusedField: FocusField?
    @State var searchText: String = ""
    
    @ObservedObject private var proteinRCSBImportViewModel = ProteinRCSBImportViewModel()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color(UIColor.secondarySystemBackground))
                        HStack {
                            Image(systemName: "magnifyingglass")
                            TextField("None",
                                      text: $searchText,
                                      prompt: Text(NSLocalizedString("Enter RCSB ID", comment: "")))
                                .frame(height: 40)
                                .focused($focusedField, equals: .field)
                                .disableAutocorrection(true)
                                .onAppear(perform: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        self.focusedField = .field
                                    }
                                })
                                .onSubmit {
                                    self.focusedField = .none
                                    Task {
                                        try await self.proteinRCSBImportViewModel.getPDBInfo(rcsbid: searchText)
                                        try await self.proteinRCSBImportViewModel.getPDBImage(rcsbid: searchText)
                                    }
                                }
                        }
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    }
                    .frame(height: 40)
                    .cornerRadius(13)
                }
                .padding(.horizontal)
 
                List {
                    if self.proteinRCSBImportViewModel.showRow {
                        ProteinRCSBRowView(title: $proteinRCSBImportViewModel.foundProteinName,
                                           description: $proteinRCSBImportViewModel.foundProteinDescription,
                                           image: $proteinRCSBImportViewModel.foundProteinImage)
                            .onTapGesture {
                                Task {
                                    guard let rcsbId = proteinRCSBImportViewModel.foundProteinName else { return }
                                    try await proteinRCSBImportViewModel.fetchPDBFile(rcsbid: rcsbId, proteinViewModel: proteinViewModel)
                                }
                                dismiss()
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .edgesIgnoringSafeArea(.all)
                
            }
            .navigationTitle(NSLocalizedString("RCSB ID", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                dismiss()
            },
                                                label: {
                Text("Close")
            }))
        }
    }
}

struct ProteinRCSBImportView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinRCSBImportView()
    }
}
