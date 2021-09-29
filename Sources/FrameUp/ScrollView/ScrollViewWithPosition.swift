//
//  ScrollViewWithPosition.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-07-01.
//

import SwiftUI


//public struct EdgeInsetKey: PreferenceKey {
//    public static var defaultValue: EdgeInsets? = nil
//    public static func reduce(value: inout EdgeInsets?, nextValue: () -> EdgeInsets?) {
//        value = nextValue()
//    }
//}

//public struct SizeKey: PreferenceKey {
//    public static var defaultValue: CGSize = .zero
//    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
//        value = nextValue()
//    }
//}
//
//public struct ScrollViewWithPosition<Content: View>: View {
//    let axes: Axis.Set
//    let showsIndicators: Bool
//    @Binding var edgeInsets: EdgeInsets?
//    let content: Content
//    
//    @State private var size: CGSize? = nil
//    
//    public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, edgeInsets: Binding<EdgeInsets?>, content: () -> Content) {
//        self.axes = axes
//        self.showsIndicators = showsIndicators
//        self._edgeInsets = edgeInsets
//        self.content = content()
//    }
//    
//    public var body: some View {
//        GeometryReader { proxy in
//            ScrollView(axes, showsIndicators: showsIndicators) {
//                content
//                    .anchorPreference(key: EdgeInsetKey.self, value: .bounds) {
//                        let rect = proxy[$0]
//                        let top = rect.minY
//                        let bottom = proxy.size.height - rect.maxY
//                        let leading = rect.minX
//                        let trailing = proxy.size.width - rect.maxX
//                        return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
//                    }
//                    .anchorPreference(key: SizeKey.self, value: .bounds) {
//                        CGSize(width: min(proxy.size.width, proxy[$0].width), height: min(proxy.size.height, proxy[$0].height))
//                    }
//            }
////            .anchorPreference(key: SizeKey.self, value: .bounds) {
////                proxy[$0].size
////            }
//        }
//        .frame(width: size?.width, height: size?.height)
//        .onPreferenceChange(EdgeInsetKey.self) { value in
//            edgeInsets = value
//        }
//        .onPreferenceChange(SizeKey.self) { value in
//            size = value
//        }
//    }
//}
