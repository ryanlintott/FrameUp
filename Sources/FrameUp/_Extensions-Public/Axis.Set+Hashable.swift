//
//  Axis.Set+Hashable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-10-19.
//

import SwiftUI

#if compiler(<6)
extension Axis.Set: Hashable { }
#else
extension Axis.Set: @retroactive Hashable { }
#endif
