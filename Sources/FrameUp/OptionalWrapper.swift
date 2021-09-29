//
//  OptionalWrapper.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-24.
//

import SwiftUI

//public struct OptionalWrapper<Wrapper: View, Content: View>: View {
//    let isOn: Bool
//    let wrapper: (() -> Content) -> Wrapper
//    let content: () -> Content
//    
//    public init(_ isOn: Bool, wrapper: @escaping (() -> Content) -> Wrapper, content: @escaping () -> Content) {
//        self.isOn = isOn
//        self.wrapper = wrapper
//        self.content = content
//    }
//    
//    public var body: some View {
//        if isOn {
//            wrapper(content)
//        } else {
//            content()
//        }
//    }
//}
