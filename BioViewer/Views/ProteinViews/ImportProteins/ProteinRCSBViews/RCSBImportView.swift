//
//  RCSBImportView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

@MainActor struct RCSBImportView: View {
    
    enum FocusField: Hashable {
        case field
      }
    
    @Binding var rcsbShowSheet: Bool
    @State var searchText: String = ""
    @State var alertText: String = ""
    @State var showingAlert: Bool = false
    
    @State var rcsbImportViewModel = RCSBImportViewModel()
    
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
                List {
                    if let results = rcsbImportViewModel.results {
                        Section(
                            content: {
                                ForEach(results) { result in
                                    RCSBRowView(
                                        pdbInfo: result,
                                        searchTerm: searchText,
                                        rcsbShowSheet: $rcsbShowSheet
                                    )
                                    .onAppear {
                                        if result == results.last {
                                            rcsbImportViewModel.loadNextPageIfNeeded()
                                        }
                                    }
                                }
                            },
                            footer: {
                                if rcsbImportViewModel.isLoading {
                                    HStack {
                                        Spacer()
                                        BVProgressView(size: 36, strokeWidth: 1.5)
                                            .foregroundStyle(.gray)
                                        Text("Loading")
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                    .padding()
                                    .padding(.bottom, 48)
                                }
                            }
                        )
                    }
                }
                .listStyle(.plain)
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    if let results = rcsbImportViewModel.results {
                        if results.isEmpty {
                            Text(NSLocalizedString("No results", comment: ""))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        if !rcsbImportViewModel.isLoading {
                            RCSBEmptyImportView(rcsbShowSheet: $rcsbShowSheet)
                        } else {
                            BVProgressView(size: 96)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle(NSLocalizedString("RCSB Search", comment: ""))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button(action: {
                rcsbShowSheet = false
            },
                                                label: {
                Text("Close")
            }), trailing: NavigationLink(destination: RCSBSuggestionsView(rcsbShowSheet: $rcsbShowSheet)) {
                Image(systemName: "lightbulb.circle")
            })
            #endif
        }
        .environment(rcsbImportViewModel)
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
                        try await rcsbImportViewModel.search(text: searchText)
                    } catch let error {
                        showAlert(text: error.localizedDescription)
                    }
                }
            }
        }
        .clipped()
        .background {
            Color.secondarySystemBackground
                .cornerRadius(12)
        }
        .foregroundColor(.gray)
        .padding()
    }
}
