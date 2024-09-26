//
//  InfoDictionary.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-11.
//

#if os(iOS)
import SwiftUI

enum InfoDictionary {
    static let supportedInterfaceOrientations: [FUInterfaceOrientation] = {
        if let orientations = Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String] {
            return orientations.compactMap { FUInterfaceOrientation(key: $0) }
        } else {
            return []
        }
    }()
}
#endif
