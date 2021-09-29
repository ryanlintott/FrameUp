//
//  OptionalScrollView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-24.
//

import SwiftUI

//public struct OptionalScrollViewSettings: Equatable {
//    public var axes: Axis.Set?
//    public var size: CGSize?
//
//    public static var defaultValue: Self {
//        OptionalScrollViewSettings(axes: nil, size: nil)
//    }
//}
//
//public struct OptionalScrollViewKey: PreferenceKey {
//    public typealias Value = OptionalScrollViewSettings
//    public static let defaultValue: OptionalScrollViewSettings = .defaultValue
//    public static func reduce(value: inout OptionalScrollViewSettings, nextValue: () -> OptionalScrollViewSettings) {
//        value = nextValue()
//    }
//}
//
//public struct OptionalScrollView<Content: View>: View {
//    let optionalAxes: Axis.Set
//    let showsIndicators: Bool
//    let content: Content
//    
//    @State private var size: CGSize? = nil
//    @State private var axes: Axis.Set? = nil
//    
//    public init(_ optionalAxes: Axis.Set = .vertical, showsIndicators: Bool = true, content: () -> Content) {
//        self.optionalAxes = optionalAxes
//        self.showsIndicators = showsIndicators
//        self.content = content()
//    }
//    
//    public var body: some View {
//        GeometryReader { proxy in
//            ScrollView(axes ?? optionalAxes, showsIndicators: showsIndicators) {
//                content
//                    .anchorPreference(key: OptionalScrollViewKey.self, value: .bounds) {
//                        let size = CGSize(width: min(proxy.size.width, proxy[$0].width), height: min(proxy.size.height, proxy[$0].height))
//                        
//                        var axes: Axis.Set = []
//                        if optionalAxes.contains(.vertical) && proxy[$0].height > proxy.size.height {
//                            axes.update(with: .vertical)
//                        }
//                        if optionalAxes.contains(.horizontal) && proxy[$0].width > proxy.size.width {
//                            axes.update(with: .horizontal)
//                        }
//                        
//                        return OptionalScrollViewSettings(axes: axes, size: size)
//                    }
//            }
//        }
//        .frame(width: size?.width, height: size?.height, alignment: .center)
//        .onPreferenceChange(OptionalScrollViewKey.self) { value in
//            size = value.size
//            axes = value.axes
//        }
//    }
//}
