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
    case metalFXUpscalingSettings
    /// This will still create a DisclosureGroup, but not persistent.
    case error
}

struct PersistentDisclosureGroup<Content: View, LabelContent: View>: View {
    
    @State var isExpanded: Bool
    
    let group: PersistentGroupName
    let content: () -> Content
    let label: () -> LabelContent
    
    init(for group: PersistentGroupName, defaultOpen: Bool, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: @escaping () -> LabelContent) {
        self.group = group
        self.content = content
        self.label = label
        guard group != .error else {
            _isExpanded = State(initialValue: false)
            return
        }
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
            guard group != .error else { return }
            UserDefaults.standard.setValue(newValue, forKey: group.rawValue + "Expanded")
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
