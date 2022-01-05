//
//  TabMenuView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

/// Customizable tab menu bar view designed to mimic the style of the default tab menu bar.
///
/// Images or views and name provied are used to mask another provided view which is often a color.
///
///     let items = [
///        TabMenuItem(image: Image(systemName: "globe"), name: "Info", tab: 0),
///        TabMenuItem(image: Image(systemName: "star"), name: "Favourites", tab: 1),
///        TabMenuItem(image: Image(systemName: "bookmark"), name: "Categories", tab: 2),
///        TabMenuItem(image: Image(systemName: "books.vertical"), name: "About", tab: 3)
///     ]
///
///     TabMenuView(selection: $selection, items: items) { isSelected in
///        Group {
///            if isSelected {
///                Color.accentColor
///            } else {
///                Color(.secondaryLabel)
///            }
///        }
///     } onReselect: {
///         print("TabMenu item \(selection) reselected")
///     } onDoubleTap: {
///         print("TabMenu item \(selection) doubletapped")
///     }
///
public struct TabMenuView<Tab: Hashable, Content: View>: View {
    @Binding var selection: Tab
    let items: [TabMenuItem<Tab>]
    let maskedView: (Bool) -> Content
    let isShowingName: Bool
    let onReselect: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    
    /// Creates a customized tab menu view
    /// - Parameters:
    ///   - selection: binding for the selected tab
    ///   - items: array of `TabMenuItem`
    ///   - isShowingName: A Boolean value that indicates whether the name should be shown. Default is true if any tab menu item has a non-nil name.
    ///   - maskedView: A view that will be shown, masked by the icon and text. A simple color or a more complex view can be provided. A Boolean value with the selected state is passed in so that the view can change accordingly.
    ///   - onReselect: A function run when a selected tab is reselected.
    ///   - onDoubleTap: A function run when a tab is tapped twice.
    public init(selection: Binding<Tab>, items: [TabMenuItem<Tab>], isShowingName: Bool? = nil, maskedView: @escaping (Bool) -> Content, onReselect: (() -> Void)? = nil, onDoubleTap: (() -> Void)? = nil) {
        self._selection = selection
        self.items = items
        self.isShowingName = isShowingName ?? (items.first(where: { $0.name != nil }) != nil)
        self.maskedView = maskedView
        self.onReselect = onReselect
        self.onDoubleTap = onDoubleTap
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                HStack {
                    maskedView(selection == item.tab)
                        .mask(
                            VStack(spacing: 2) {
                                Spacer(minLength: 0)
                                
                                item.icon
                                    .scaledToFit()
                                    .frame(height: 22)
                                
                                if isShowingName {
                                    if let name = item.name {
                                        Text(name)
                                    }
                                }
                            }
                        )
                        .gesture(TapGesture(count: 2).onEnded {
                            onDoubleTap?()
                        })
                        .simultaneousGesture(TapGesture().onEnded {
                            if selection == item.tab {
                                onReselect?()
                            } else {
                                selection = item.tab
                            }
                        })
                        .accessibilityLabel(tabVoiceOverLabel(tabItem: item))
                        .accessibilityHint(tabVoiceOverHint(tabItem: item))
                        .accessibilityAddTraits(selection == item.tab ? .isSelected : [])
                        
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
            }
        }
        .font(.system(size: 10))
        .padding(.bottom, 2)
        .padding(.horizontal, 1)
        .frame(height: 50)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Tab bar"))
    }
    
    func tabVoiceOverLabel(tabItem: TabMenuItem<Tab>) -> Text {
        let tabName = tabItem.name ?? "\(tabItem.tab.hashValue)"
        
        return Text(tabName)
    }
    
    func tabVoiceOverHint(tabItem: TabMenuItem<Tab>) -> Text {
        guard let tabIndex = items.firstIndex(where: { $0.tab == tabItem.tab }) else {
            return Text("")
        }
        
        return Text("Tab\n\(tabIndex + 1) of \(items.count)")
    }
    
    // Old Tab VoiceOver function
//    func tabVoiceOver(tabItem: TabMenuItem<Tab>) -> Text {
//        var tabString = ""
//        if let tabIndex = items.firstIndex(where: { $0.tab == tabItem.tab }) {
//            tabString = "\(tabIndex + 1) of \(items.count)"
//        }
//        let tabName = tabItem.name ?? "\(tabItem.tab.hashValue)"
//        
//        return Text("\(tabName)\nTab\n\(tabString)")
//    }
}
