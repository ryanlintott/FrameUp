//
//  TabMenuExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-15.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct TabMenuExample: View {
    @Binding var selection: Int
    let onReselect: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    
    internal init(selection: Binding<Int>, onReselect: (() -> Void)? = nil, onDoubleTap: (() -> Void)? = nil) {
        self._selection = selection
        self.onReselect = onReselect
        self.onDoubleTap = onDoubleTap
    }
    
    static var items: [TabMenuItem<Int>] {
        [
            TabMenuItem("Info", tab: 0) {
                Circle().stroke().overlay(Text("i"))
            },
            TabMenuItem("Favourites", systemImage: "star", tab: 1),
            TabMenuItem("Categories", systemImage: "bookmark", tab: 2),
            TabMenuItem("About", systemImage: "books.vertical", tab: 3)
        ]
    }

    /// A fill for the masked style that changes along the item.
    @ViewBuilder
    static func gradientFill(isSelected: Bool) -> some View {
        if isSelected {
            LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
        } else {
            Color(.secondaryLabel)
        }
    }

    var body: some View {
        TabMenu(selection: $selection, items: Self.items)
            .tabMenuItemStyle(.masked { isSelected in
                isSelected ? Color.accentColor : Color(.secondaryLabel)
            })
            .onTabMenuItemReselect("Reselect") {
                onReselect?()
                print("TabMenu item \(selection) reselected")
            }
            .onTabMenuItemDoubleTap("Double Tap") {
                onDoubleTap?()
                print("TabMenu item \(selection) doubletapped")
            }
    }
}

struct DefaultTabView: View {
    @Binding var selection: Int
    
    var body: some View {
        TabView(selection: $selection) {
            Color.blue
                .tabItem {
                    Image(systemName: "globe")
                    Text("Info")
                }
                .tag(0)
            
            Color.white
                .tabItem {
                    Image(systemName: "star")
                    Text("Favourites")
                }
                .tag(1)
            
            Color.white
                .tabItem {
                    Image(systemName: "bookmark")
                    Text("Categories")
                }
                .tag(2)
            
            Color.white
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("About")
                }
                .tag(3)
        }
    }
}

struct TabMenuExample_Previews: PreviewProvider {
    static var previews: some View {
        TabMenuExample(selection: .constant(0))
            .previewLayout(.sizeThatFits)
        
        ZStack {
            // Default SwiftUI TabView for comparison
            DefaultTabView(selection: .constant(0))
            
            VStack(spacing: 0) {
                Color.red.opacity(0.5)
                
                TabMenuExample(selection: .constant(0))
            }
        }
    }
}
#endif
