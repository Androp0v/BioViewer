//
//  PersistentDisclosureGroup.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 15/12/22.
//

import SwiftUI

enum PersistentGroupName: String {
    case colorGroup
    case visualizationGroup
    case solidSpheresRadiusGroup
    case ballAndStickRadiusGroup
    case shadowGroup
    case depthCueingGroup
    case residueColoringAminoAcid
    case residueColoringDNANucleobase
    case residueColoringRNANucleobase
}

struct PersistentDisclosureGroup<Content: View, LabelContent: View>: View {
    
    @State var isExpanded: Bool
    
    let groupName: String
    let content: () -> Content
    let label: () -> LabelContent
    
    init(for group: PersistentGroupName, defaultOpen: Bool, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> LabelContent) {
        self.groupName = group.rawValue + "Expanded"
        self.content = content
        self.label = label
        
        if UserDefaults.standard.object(forKey: group.rawValue + "Expanded") != nil {
            _isExpanded = State(initialValue: UserDefaults.standard.bool(forKey: group.rawValue + "Expanded"))
        } else {
            _isExpanded = State(initialValue: defaultOpen)
        }
    }
        
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: content,
            label: label
        )
        .onChange(of: isExpanded) { newValue in
            UserDefaults.standard.setValue(newValue, forKey: groupName)
        }
    }
}

struct PersistentDisclosureGroup_Previews: PreviewProvider {
    static var previews: some View {
        PersistentDisclosureGroup(
            for: .colorGroup,
            defaultOpen: true,
            content: {
                Rectangle()
            },
            label: {
                Circle()
            }
        )
    }
}
