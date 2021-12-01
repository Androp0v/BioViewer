//
//  RCSBImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct RCSBImportView: View {
    
    enum FocusField: Hashable {
        case field
      }
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    // TO-DO: Make rcsbShowSheet an environmental variable
    @Binding var rcsbShowSheet: Bool
    @State var searchText: String = ""
    @State var alertText: String = ""
    @State var showingAlert: Bool = false
    
    @StateObject var proteinRCSBImportViewModel = RCSBImportViewModel()
    
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
                
                if !searchText.isEmpty {
                    List {
                        if self.proteinRCSBImportViewModel.showRow {
                            RCSBRowView(title: proteinRCSBImportViewModel.foundProteinName,
                                        description: proteinRCSBImportViewModel.foundProteinDescription,
                                        authors: proteinRCSBImportViewModel.foundProteinAuthors,
                                        image: proteinRCSBImportViewModel.foundProteinImage,
                                        rcsbShowSheet: $rcsbShowSheet)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .edgesIgnoringSafeArea(.all)
                } else {
                    RCSBEmptyImportView(rcsbShowSheet: $rcsbShowSheet)
                }
                
            }
            .navigationTitle(NSLocalizedString("RCSB ID", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                rcsbShowSheet = false
            },
                                                label: {
                Text("Close")
            }), trailing: NavigationLink(destination: RCSBSuggestionsView(rcsbShowSheet: $rcsbShowSheet)) {
                Image(systemName: "lightbulb.circle")
            })
        }
        .environmentObject(proteinRCSBImportViewModel)
    }
}

struct RCSBImportView_Previews: PreviewProvider {
    static var previews: some View {
        RCSBImportView(rcsbShowSheet: .constant(true))
    }
}
