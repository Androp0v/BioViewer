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
            VStack(alignment: .center, spacing: .zero) {
                searchBar
                Divider()
                Group {
                    if let results = proteinRCSBImportViewModel.results {
                        if !results.isEmpty {
                            List {
                                ForEach(results) { result in
                                    RCSBRowView(
                                        pdbInfo: result,
                                        searchTerm: searchText,
                                        rcsbShowSheet: $rcsbShowSheet
                                    )
                                }
                            }
                            .listStyle(.plain)
                            .edgesIgnoringSafeArea(.all)
                        } else {
                            Text(NSLocalizedString("No results", comment: ""))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        RCSBEmptyImportView(rcsbShowSheet: $rcsbShowSheet)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle(NSLocalizedString("RCSB Search", comment: ""))
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
                prompt: Text(NSLocalizedString("Enter search term or RCSB ID", comment: ""))
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
