//
//  InfoDictionary.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-11.
//

import SwiftUI

#if os(iOS)
enum InfoDictionary {
    static let supportedInterfaceOrientations: [InterfaceOrientation] = {
        if let orientations = Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String] {
            return orientations.compactMap { InterfaceOrientation(key: $0) }
        } else {
            return []
        }
    }()
}
#endif
