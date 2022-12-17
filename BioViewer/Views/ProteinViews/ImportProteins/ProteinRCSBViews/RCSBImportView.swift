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
    
    // MARK: - View body
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: .zero) {
                searchBar
                Divider()
                if !searchText.isEmpty && !proteinRCSBImportViewModel.results.isEmpty {
                    List {
                        ForEach(proteinRCSBImportViewModel.results) { result in
                            RCSBRowView(
                                pdbInfo: result,
                                rcsbShowSheet: $rcsbShowSheet
                            )
                        }
                    }
                    .listStyle(.plain)
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxHeight: .infinity)
                } else {
                    RCSBEmptyImportView(rcsbShowSheet: $rcsbShowSheet)
                        .frame(maxHeight: .infinity)
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
    
    // MARK: - SearchBar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .padding(.leading, 8)
                .padding(.vertical, 8)
            TextField(
                "None",
                text: $searchText,
                prompt: Text(NSLocalizedString("Enter RCSB ID", comment: ""))
            )
            .padding(.vertical, 8)
            .disableAutocorrection(true)
            .alert(alertText, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            .onSubmit {
                Task {
                    do {
                        try await proteinRCSBImportViewModel.search(text: searchText)
                    } catch let error {
                        showAlert(text: error.localizedDescription)
                    }
                    // FIXME: Remove
                    /*
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
                     */
                }
            }
        }
        .clipped()
        .background {
            Color(UIColor.secondarySystemBackground)
                .cornerRadius(12)
        }
        .foregroundColor(.gray)
        .padding()
    }
}

// MARK: - Previews

struct RCSBImportView_Previews: PreviewProvider {
    static var previews: some View {
        RCSBImportView(rcsbShowSheet: .constant(true))
    }
}
