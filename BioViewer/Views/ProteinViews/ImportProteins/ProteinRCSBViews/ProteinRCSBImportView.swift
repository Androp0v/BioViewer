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
    @State var searchText: String = ""
    @State var alertText: String = ""
    @State var showingAlert: Bool = false
    
    @StateObject var proteinRCSBImportViewModel = ProteinRCSBImportViewModel()
    
    func showAlert(text: String) {
        DispatchQueue.main.async {
            self.alertText = text
            self.showingAlert = true
        }
    }
    
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
                                .frame(maxHeight: .infinity)
                                .disableAutocorrection(true)
                                .alert(alertText, isPresented: $showingAlert) {
                                    Button("OK", role: .cancel) { }
                                }
                                .onSubmit {
                                    Task {
                                        await withThrowingTaskGroup(of: Void.self, body: { group in
                                            group.addTask {
                                                do {
                                                    try await self.proteinRCSBImportViewModel.getPDBInfo(rcsbid: searchText)
                                                } catch let error {
                                                    await showAlert(text: error.localizedDescription)
                                                }
                                            }
                                            group.addTask {
                                                do {
                                                    try await self.proteinRCSBImportViewModel.getPDBImage(rcsbid: searchText)
                                                } catch let error {
                                                    await showAlert(text: error.localizedDescription)
                                                }
                                            }
                                        })
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
                        ProteinRCSBRowView(title: proteinRCSBImportViewModel.foundProteinName,
                                           description: proteinRCSBImportViewModel.foundProteinDescription,
                                           image: proteinRCSBImportViewModel.foundProteinImage)
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
