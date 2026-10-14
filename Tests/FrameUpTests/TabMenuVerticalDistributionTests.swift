//
//  TabMenuVerticalDistributionTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

struct TabMenuVerticalDistributionTests {
    @Test func automaticIsGroupedInTheSystemToolbarVertical() {
        #expect(TabMenuVerticalDistribution.automatic.isGrouped(in: .system(.trailing)))
    }

    @Test func automaticIsEqualInTheCustomBar() {
        #expect(!TabMenuVerticalDistribution.automatic.isGrouped(in: .custom(.trailing)))
    }

    @Test func explicitDistributionsIgnoreTheBar() {
        for bar in [TabMenuVerticalBar.system(.leading), .custom(.leading)] {
            #expect(TabMenuVerticalDistribution.grouped.isGrouped(in: bar))
            #expect(!TabMenuVerticalDistribution.equal.isGrouped(in: bar))
        }
    }
}
#endif
