//
//  PhotoModeConfigList.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 19/12/21.
//

import SwiftUI

struct PhotoModeConfigList: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init() {
       UITableViewCell.appearance().backgroundColor = .clear
       UITableView.appearance().backgroundColor = .clear
    }
    
    struct ListContent: View {
        var body: some View {
            PickerRow(optionName: NSLocalizedString("Image resolution", comment: ""),
                      selectedOption: .constant(1),
                      pickerOptions: ["1024x1024", "2048x2048", "4096x4096"])
            PickerRow(optionName: NSLocalizedString("Shadow resolution", comment: ""),
                      selectedOption: .constant(1),
                      pickerOptions: ["Normal", "High", "Very high"])
            PickerRow(optionName: NSLocalizedString("Shadow smoothing", comment: ""),
                      selectedOption: .constant(1),
                      pickerOptions: ["Normal", "High", "Very high"])
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Configuration", comment: ""))
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
            if horizontalSizeClass == .compact {
                List {
                    ListContent()
                }
                .listStyle(GroupedListStyle())

            } else {
                List {
                    ListContent()
                }
                .listStyle(PlainListStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct PhotoModeConfigList_Previews: PreviewProvider {
    static var previews: some View {
        PhotoModeConfigList()
    }
}
