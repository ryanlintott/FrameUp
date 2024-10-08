//
//  UnavailableView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct UnavailableView: View {
    let availableInLaterVersion: Bool
    
    init(availableInLaterVersion: Bool = false) {
        self.availableInLaterVersion = availableInLaterVersion
    }
    
    var os: String {
        #if os(iOS)
        "iOS"
        #elseif os(visionOS)
        "visionOS"
        #elseif os(macOS)
        "macOS"
        #elseif os(tvOS)
        "tvOS"
        #endif
    }
    
    var osVersion: String {
        [
            os,
            String(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)
        ]
        .joined(separator: " ")
    }
    
    var body: some View {
        Label("Unavailable in \(availableInLaterVersion ? osVersion : os)", systemImage: "xmark.circle")
    }
}

struct UnavailableView_Previews: PreviewProvider {
    static var previews: some View {
        UnavailableView()
    }
}
