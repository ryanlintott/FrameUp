//
//  FUCounterRotationStyle+Examples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import FrameUp

extension FUCounterRotationStyle {
    /// The behaviors available on this version of iOS, to choose from in an example.
    static var exampleCases: [Self] {
        if #available(iOS 17, *) {
            [.system, .hold]
        } else {
            [.system]
        }
    }

    /// The behavior an example starts with: hold where it's available.
    static var exampleDefault: Self {
        if #available(iOS 17, *) {
            .hold
        } else {
            .system
        }
    }
}
#endif
