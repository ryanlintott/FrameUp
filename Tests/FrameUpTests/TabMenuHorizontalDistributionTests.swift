//
//  TabMenuHorizontalDistributionTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-14.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

struct TabMenuHorizontalDistributionTests {
    @available(iOS 16, *)
    @Test func automaticIsEqualWhereTheWidthIsCompact() {
        #expect(TabMenuHorizontalDistribution.automatic.itemLayout(for: .compact) == (.infinity, 0))
    }

    @available(iOS 16, *)
    @Test func automaticIsGroupedWhereTheWidthIsRegular() {
        #expect(TabMenuHorizontalDistribution.automatic.itemLayout(for: .regular) == TabMenuHorizontalDistribution.automaticGrouped.itemLayout(for: .regular))
    }

    @available(iOS 16, *)
    @Test func automaticIsEqualWithoutASizeClass() {
        #expect(TabMenuHorizontalDistribution.automatic.itemLayout(for: nil) == (.infinity, 0))
    }

    @available(iOS 16, *)
    @Test func explicitDistributionsIgnoreTheSizeClass() {
        #expect(TabMenuHorizontalDistribution.grouped(maxItemWidth: 60, spacing: 4).itemLayout(for: .compact) == (60, 4))
        #expect(TabMenuHorizontalDistribution.equal.itemLayout(for: .regular) == (.infinity, 0))
    }
}
#endif
