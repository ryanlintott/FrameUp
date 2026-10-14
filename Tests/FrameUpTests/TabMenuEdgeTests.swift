//
//  TabMenuEdgeTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

#if os(iOS)
import SwiftUI
import Testing
@testable import FrameUp

struct TabMenuEdgeTests {
    /// The edge `tabMenu(selection:items:)` gives the menu it places, for the bar `.automatic` decides on an iPhone, with the top of the device on the left unless told otherwise.
    @available(iOS 16, *)
    private func menuEdge(
        systemEdge: HorizontalEdge? = nil,
        verticalSizeClass: UserInterfaceSizeClass? = .compact,
        interfaceOrientation: FUInterfaceOrientation? = .landscapeLeft,
        layoutDirection: LayoutDirection = .leftToRight
    ) -> Edge {
        Edge.edge(for: TabMenuVerticalBar(
            behavior: .automatic,
            systemEdge: systemEdge,
            verticalSizeClass: verticalSizeClass,
            interfaceOrientation: interfaceOrientation,
            layoutDirection: layoutDirection
        ))
    }

    @available(iOS 16, *)
    @Test func bottomMenuIsAgainstTheBottomEdge() {
        #expect(menuEdge(verticalSizeClass: .regular) == .bottom)
    }

    @available(iOS 16, *)
    @Test func systemToolbarVerticalMenuIsAgainstItsEdge() {
        #expect(menuEdge(systemEdge: .leading) == .leading)
        #expect(menuEdge(systemEdge: .trailing) == .trailing)
        #expect(menuEdge(systemEdge: .leading, layoutDirection: .rightToLeft) == .leading)
        #expect(menuEdge(systemEdge: .trailing, layoutDirection: .rightToLeft) == .trailing)
    }

    @available(iOS 16, *)
    @Test func customBarMenuIsAgainstTheBarsEdge() {
        #expect(menuEdge(interfaceOrientation: .landscapeLeft) == .trailing)
        #expect(menuEdge(interfaceOrientation: .landscapeRight) == .leading)
    }

    @available(iOS 16, *)
    @Test func customBarMenuEdgeIsLayoutRelativeInRightToLeft() {
        /// The bar keeps its physical side, so its layout edge swaps.
        #expect(menuEdge(interfaceOrientation: .landscapeLeft, layoutDirection: .rightToLeft) == .leading)
        #expect(menuEdge(interfaceOrientation: .landscapeRight, layoutDirection: .rightToLeft) == .trailing)
    }

    @Test func handPlacedMenuHasNoEdge() {
        #expect(EnvironmentValues().tabMenuEdge == nil)
    }

    @MainActor
    @Test func axisFollowsEdge() {
        let label = TabMenuItem("Info", systemImage: "info.circle", tab: 0).label
        func axis(_ edge: Edge?) -> Axis {
            TabMenuItemStyleConfiguration(label: label, isSelected: false, edge: edge).axis
        }
        #expect(axis(.bottom) == .horizontal)
        #expect(axis(nil) == .horizontal)
        #expect(axis(.leading) == .vertical)
        #expect(axis(.trailing) == .vertical)
    }
}
#endif
