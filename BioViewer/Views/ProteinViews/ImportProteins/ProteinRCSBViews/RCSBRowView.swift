//
//  ProteinRCSBRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct RCSBRowView: View {
    
    var pdbInfo: PDBInfo
    var searchTerm: String?
    @State var image: Image?
    @State var showError: Bool = false
        
    @Binding var rcsbShowSheet: Bool
    
    @Environment(ProteinDataSource.self) var proteinDataSource: ProteinDataSource
    @Environment(StatusViewModel.self) var statusViewModel: StatusViewModel
    @Environment(RCSBImportViewModel.self) var rcsbImportViewModel: RCSBImportViewModel
    
    private enum Constants {
        #if targetEnvironment(macCatalyst)
        static let imageCornerRadius: CGFloat = 4
        #else
        static let imageCornerRadius: CGFloat = 8
        #endif
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack {
                Color.white
                if showError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                        .foregroundColor(.red)
                }
                if let image, !showError {
                    image
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 96)
                }
                RoundedRectangle(cornerRadius: Constants.imageCornerRadius)
                    .stroke(
                        Color.separator,
                        style: StrokeStyle(lineWidth: 2)
                    )
                    .opacity(0.5)
            }
            .cornerRadius(Constants.imageCornerRadius)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: 96, height: 96)
            .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 4) {
                rcsbIDText(pdbInfo.rcsbID)
                titleText(pdbInfo.title)
                descriptionText(pdbInfo.description)
                Text(pdbInfo.authors)
                    .foregroundColor(.secondaryLabel)
                    .italic()
            }
            .padding()
        }
        .frame(minHeight: 108)
        .onTapGesture {
            Task {
                try await rcsbImportViewModel.fetchPDBFile(
                    pdbInfo: pdbInfo,
                    proteinDataSource: proteinDataSource,
                    statusViewModel: statusViewModel
                )
            }
            rcsbShowSheet = false
        }
        .onAppear {
            // Check if image had been downloaded before, to avoid re-fetching on
            // list reuse.
            if let existingImage = rcsbImportViewModel.resultImages[pdbInfo] {
                image = existingImage
                return
            }
            Task {
                var newImage: Image?
                do {
                    newImage = try await RCSBFetch.fetchPDBImage(rcsbid: pdbInfo.rcsbID)
                    rcsbImportViewModel.resultImages[pdbInfo] = newImage
                } catch {
                    showError = true
                }
                withAnimation {
                    image = newImage
                }
            }
        }
    }
    
    private func rcsbIDText(_ rcsbID: String) -> some View {
        Group {
            if rcsbID.lowercased() == searchTerm?.lowercased() {
                Text(rcsbID)
                    .foregroundColor(.accentColor)
            } else {
                Text(rcsbID)
            }
        }
        .font(.title2)
        .bold()
    }
    
    private func titleText(_ title: String) -> some View {
        Group {
            title.components(separatedBy: .whitespaces).reduce(Text(""), { currentText, nextWord in
                if let searchTerm, nextWord.localizedCaseInsensitiveContains(searchTerm) {
                    return currentText + Text(nextWord).foregroundColor(.accentColor) + Text(" ")
                } else {
                    return currentText + Text(nextWord) + Text(" ")
                }
            })
        }
        .font(.headline)
    }
    
    private func descriptionText(_ description: String) -> some View {
        Group {
            description.components(separatedBy: .whitespaces).reduce(Text(""), { currentText, nextWord in
                if let searchTerm, nextWord.localizedCaseInsensitiveContains(searchTerm) {
                    return currentText + Text(nextWord).foregroundColor(.accentColor) + Text(" ")
                } else {
                    return currentText + Text(nextWord) + Text(" ")
                }
            })
        }
        .lineLimit(5)
    }
}
