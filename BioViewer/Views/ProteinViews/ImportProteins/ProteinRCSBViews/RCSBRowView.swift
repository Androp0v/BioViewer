//
//  ProteinRCSBRowView.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 6/11/21.
//

import SwiftUI

struct RCSBRowView: View {
    
    var pdbInfo: PDBInfo
    @State var image: Image?
    @State var showError: Bool = false
        
    @Binding var rcsbShowSheet: Bool
    
    @EnvironmentObject var proteinViewModel: ProteinViewModel
    @EnvironmentObject var rcsbImportViewModel: RCSBImportViewModel
    
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
                        .aspectRatio(1.0, contentMode: .fit)
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
                    .stroke(Color(uiColor: .separator),
                            style: StrokeStyle(lineWidth: 2))
                    .opacity(0.2)
            }
            .cornerRadius(Constants.imageCornerRadius)
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: 96)
            .padding(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pdbInfo.rcsbID)
                    .font(.title2)
                    .bold()
                Text(pdbInfo.title)
                    .font(.headline)
                Text(pdbInfo.description)
                Text(pdbInfo.authors)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    .italic()
            }
            .padding()
        }
        .listRowInsets(EdgeInsets())
        .onTapGesture {
            Task {
                try await rcsbImportViewModel.fetchPDBFile(pdbInfo: pdbInfo, proteinViewModel: proteinViewModel)
            }
            rcsbShowSheet = false
        }
        .task {
            var newImage: Image?
            do {
                newImage = try await RCSBFetch.fetchPDBImage(rcsbid: pdbInfo.rcsbID)
            } catch {
                showError = true
            }
            withAnimation {
                image = newImage
            }
        }
    }
}
