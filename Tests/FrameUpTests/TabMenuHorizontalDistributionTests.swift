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
    @Test func automaticIsEqualWhereTheWidthIsCompact() {
        #expect(TabMenuHorizontalDistribution.automatic.resolved(for: .compact) == .equal)
    }

    @Test func automaticIsGroupedWhereTheWidthIsRegular() {
        #expect(TabMenuHorizontalDistribution.automatic.resolved(for: .regular) == .automaticGrouped)
    }

    @Test func automaticIsEqualWithoutASizeClass() {
        #expect(TabMenuHorizontalDistribution.automatic.resolved(for: nil) == .equal)
    }

    @Test func explicitDistributionsIgnoreTheSizeClass() {
        let grouped = TabMenuHorizontalDistribution.grouped(maxItemWidth: 60, spacing: 4)
        #expect(grouped.resolved(for: .compact) == grouped)
        #expect(TabMenuHorizontalDistribution.equal.resolved(for: .regular) == .equal)
    }
}
#endif
