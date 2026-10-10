//
//  TabMenuFullscreenExampleView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-09-25.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct TabMenuFullscreenExampleView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selection = 0
    @State private var isSystemTabBar = false
    @State private var isGrouped = false
    @State private var itemStyle: ExampleTabMenuItemStyleChoice = .automatic
    @State private var verticalBehavior: ToolbarVerticalBehaviorIfAvailable = .automatic
    @State private var tabMenuVerticalBehavior: TabMenuVerticalBehavior = .system

    var body: some View {
        Group {
            if isSystemTabBar {
                TabView(selection: $selection) {
                    page(0).tabItem { Label("Info", systemImage: "info.circle") }.tag(0)
                    page(1).tabItem { Label("Favourites", systemImage: "star") }.tag(1)
                    page(2).tabItem { Label("Categories", systemImage: "bookmark") }.tag(2)
                    page(3).tabItem { Label("About", systemImage: "books.vertical") }.tag(3)
                }
            } else {
                page(selection)
                    .tabMenu(selection: $selection, items: TabMenuExample.items)
                    .tabMenuItemStyle(ExampleTabMenuItemStyle(choice: itemStyle))
                    .tabMenuHorizontalDistribution(isGrouped ? .grouped(maxItemWidth: 90, spacing: 8) : .equal)
                    .tabMenuVerticalBehavior(tabMenuVerticalBehavior)
            }
        }
        .toolbarVerticalBehaviorIfAvailable(verticalBehavior)
    }

    func page(_ tab: Int) -> some View {
        Group {
            switch tab {
            case 0:
                Color.blue
                    .overlay(Text("Info"))
            case 1:
                Color.red
                    .overlay(Text("Favourites"))
            case 2:
                Color.green
                    .overlay(Text("Categories"))
            case 3:
                Color.purple
                    .overlay(Text("About"))
            default:
                Color.white
            }
        }
        .font(.system(size: 30))
        .foregroundColor(.white)
        .overlay(alignment: .top) {
            VStack {
                Toggle("System", isOn: $isSystemTabBar)
                Toggle("Grouped", isOn: $isGrouped)
                    .disabled(isSystemTabBar)
                Picker("Item style", selection: $itemStyle) {
                    ForEach(ExampleTabMenuItemStyleChoice.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isSystemTabBar)
                Text("System bar")
                    .font(.caption)
                Picker("System vertical bar", selection: $verticalBehavior) {
                    Text("Automatic").tag(ToolbarVerticalBehaviorIfAvailable.automatic)
                    Text("Disabled").tag(ToolbarVerticalBehaviorIfAvailable.disabled)
                }
                .pickerStyle(.segmented)
                Text("Tab menu")
                    .font(.caption)
                Picker("Tab menu vertical behavior", selection: $tabMenuVerticalBehavior) {
                    Text("System").tag(TabMenuVerticalBehavior.system)
                    Text("Automatic").tag(TabMenuVerticalBehavior.automatic)
                    Text("Disabled").tag(TabMenuVerticalBehavior.disabled)
                }
                .pickerStyle(.segmented)
                .disabled(isSystemTabBar)
                Button("Close", action: dismiss.callAsFunction)
            }
            .font(.body)
            .padding()
            /// Material ignores the safe area by default, which spread it under the vertical bars. It only extends under the top edge, to cover the status bar.
            .background(.ultraThinMaterial, ignoresSafeAreaEdges: .top)
        }
    }
}
#endif

