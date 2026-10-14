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
    @State private var horizontalDistribution: TabMenuHorizontalDistribution = .automatic
    @State private var itemStyle: ExampleTabMenuItemStyleChoice = .automatic
    @State private var verticalBehavior: ToolbarVerticalBehaviorIfAvailable = .automatic
    @State private var tabMenuVerticalBehavior: TabMenuVerticalBehavior = .system
    @State private var verticalDistribution: TabMenuVerticalDistribution = .automatic
    @State private var showsGeometry = false

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
                    .overlay {
                        if showsGeometry {
                            TabMenuItemsBorder()
                        }
                    }
                    .tabMenu(selection: $selection, items: TabMenuExample.items)
                    .tabMenuItemStyle(ExampleTabMenuItemStyle(choice: itemStyle))
                    .tabMenuHorizontalDistribution(horizontalDistribution)
                    .tabMenuVerticalDistribution(verticalDistribution)
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
                HStack {
                    Picker("Tab bar", selection: $isSystemTabBar) {
                        Text("Tab menu").tag(false)
                        Text("System").tag(true)
                    }
                    
                    Button("Close", action: dismiss.callAsFunction)
                        .buttonStyle(.bordered)
                }

                Text("System vertical behavior")
                    .font(.caption)
                Picker("System vertical bar", selection: $verticalBehavior) {
                    Text("Automatic").tag(ToolbarVerticalBehaviorIfAvailable.automatic)
                    Text("Disabled").tag(ToolbarVerticalBehaviorIfAvailable.disabled)
                }

                Text("Tab menu vertical behavior")
                    .font(.caption)
                Picker("Tab menu vertical behavior", selection: $tabMenuVerticalBehavior) {
                    Text("System").tag(TabMenuVerticalBehavior.system)
                    Text("Automatic").tag(TabMenuVerticalBehavior.automatic)
                    Text("Disabled").tag(TabMenuVerticalBehavior.disabled)
                }
                .disabled(isSystemTabBar)
                
                HStack {
                    Text("Horizontal")
                        .font(.caption)
                    Picker("Tab menu horizontal distribution", selection: $horizontalDistribution) {
                        Text("Automatic").tag(TabMenuHorizontalDistribution.automatic)
                        Text("Equal").tag(TabMenuHorizontalDistribution.equal)
                        Text("Grouped").tag(TabMenuHorizontalDistribution.grouped(maxItemWidth: 90, spacing: 8))
                    }
                }
                .disabled(isSystemTabBar)
                
                HStack {
                    Text("Vertical")
                        .font(.caption)
                    Picker("Tab menu vertical distribution", selection: $verticalDistribution) {
                        Text("Automatic").tag(TabMenuVerticalDistribution.automatic)
                        Text("Equal").tag(TabMenuVerticalDistribution.equal)
                        Text("Grouped").tag(TabMenuVerticalDistribution.grouped)
                    }
                }
                .disabled(isSystemTabBar)
                
                Picker("Item style", selection: $itemStyle) {
                    ForEach(ExampleTabMenuItemStyleChoice.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .disabled(isSystemTabBar)

                /// Outlines the menu's items in green.
                Toggle("Show items frame", isOn: $showsGeometry)
                    .fixedSize()
                    .disabled(isSystemTabBar)
            }
            .pickerStyle(.segmented)
            .font(.body)
            .padding()
            /// Material ignores the safe area by default, which spread it under the vertical bars. It only extends under the top edge, to cover the status bar.
            .background(.ultraThinMaterial, ignoresSafeAreaEdges: .top)
        }
    }
}

/// Outlines the menu's items from ``TabMenuGeometry`` in green.
private struct TabMenuItemsBorder: View {
    @Environment(\.tabMenuGeometry) private var tabMenuGeometry

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .tabMenu).origin
            if let itemsFrame = tabMenuGeometry?.itemsFrame {
                Rectangle()
                    .strokeBorder(.green, lineWidth: 2)
                    .frame(width: itemsFrame.width, height: itemsFrame.height)
                    .offset(x: itemsFrame.minX - origin.x, y: itemsFrame.minY - origin.y)
            }
        }
        /// Covers the menu's bar too, so the items are outlined where they are.
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    TabMenuFullscreenExampleView()
}
#endif

