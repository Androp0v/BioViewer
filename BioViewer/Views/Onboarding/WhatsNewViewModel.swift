//
//  WhatsNewViewModel.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 12/3/22.
//

import Foundation

enum NewsRowType {
    case feature
    case fix
}

struct WhatsNew: Identifiable {
    let id = UUID()
    let type: NewsRowType
    let title: String
    let subtitle: String
}

class WhatsNewViewModel: ObservableObject {
    
    @Published var newItems = [WhatsNew]()
    let version = "1.3"
    
    init() {
        var changeLog: NSDictionary?
        if let path = Bundle.main.path(forResource: "ChangeLog", ofType: "plist") {
            changeLog = NSDictionary(contentsOfFile: path)
        }
        guard let changeLog = changeLog else {
            return
        }
        guard let currentNews = changeLog[version] as? [NSDictionary] else {
            return
        }
        
        for newItem in currentNews {
            var type: NewsRowType?
            if newItem["Type"] as? String == "FEAT" {
                type = .feature
            } else if newItem["Type"] as? String == "FIX" {
                type = .fix
            }
            let title = newItem["Title"] as? String
            let subtitle = newItem["Subtitle"] as? String
            
            if let type = type, let title = title, let subtitle = subtitle {
                newItems.append(WhatsNew(type: type, title: title, subtitle: subtitle))
            }
        }
    }
}
