//
//  RCSBSuggestionsView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 1/12/21.
//

import SwiftUI

struct RCSBSuggestionHeaderView: View {
    
    let title: String?
    let description: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title ?? "")
                .bold()
                .frame(alignment: .leading)
            Text(description ?? "")
                .textCase(nil)
            Spacer()
                .frame(height: 4)
        }
    }
}

// swiftlint:disable all
struct RCSBSuggestionsView: View {
    
    @Binding var rcsbShowSheet: Bool
    let suggestionViewModel = RCSBSuggestionViewModel()
        
    var body: some View {
        List {
            if let sections = suggestionViewModel.suggestionData?.sections {
                ForEach(sections, id: \.self) { section in
                    Section(content: {
                        if let rcsbRows = section.rowData {
                            ForEach(rcsbRows, id: \.self) { rcsbRow in
                                RCSBRowView(title: rcsbRow.rcsbid,
                                            description: NSLocalizedString(rcsbRow.description, comment: ""),
                                            authors: NSLocalizedString(rcsbRow.authors, comment: ""),
                                            image: rcsbRow.pdbImage,
                                            rcsbShowSheet: $rcsbShowSheet)
                            }
                        }
                    }, header: {
                        RCSBSuggestionHeaderView(title: NSLocalizedString(section.sectionTitle,
                                                                          comment: ""),
                                                 description: NSLocalizedString(section.sectionDescription,
                                                                                comment: ""))
                    })
                }
            }
        }
        .navigationTitle(NSLocalizedString("Suggestions", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RCSBSuggestions_Previews: PreviewProvider {
    static var previews: some View {
        RCSBSuggestionsView(rcsbShowSheet: .constant(true))
    }
}
