//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-10-19.
//

import SwiftUI

/// A alignment type used for FULayout that has a limited number of cases
public enum FUAlignment: String, CaseIterable, Identifiable, Equatable, Hashable {
    case topLeading
    case top
    case topTrailing
    case leading
    case center
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing
    
    public var id: Self { self }
    
    public init(horizontal: FUHorizontalAlignment, vertical: FUVerticalAlignment) {
        switch (vertical, horizontal) {
        case (.top, .leading): self = .topLeading
        case (.top, .center): self = .top
        case (.top, .trailing): self = .topTrailing
        case (.center, .leading): self = .leading
        case (.center, .center): self = .center
        case (.center, .trailing): self = .trailing
        case (.bottom, .leading): self = .bottomLeading
        case (.bottom, .center): self = .bottom
        case (.bottom, .trailing): self = .bottomTrailing
        }
    }
    
    public var horizontal: FUHorizontalAlignment {
        switch self {
        case .topLeading, .leading, .bottomLeading:
            return .leading
        case .top, .center, .bottom:
            return .center
        case .topTrailing, .trailing, .bottomTrailing:
            return .trailing
        }
    }
    
    public var vertical: FUVerticalAlignment {
        switch self {
        case .topLeading, .top, .topTrailing:
            return .top
        case .leading, .center, .trailing:
            return .center
        case .bottomLeading, .bottom, .bottomTrailing:
            return .bottom
        }
    }
    
    public var alignment: Alignment {
        switch self {
        case .topLeading: return .topLeading
        case .top: return .top
        case .topTrailing: return .topTrailing
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        case .bottomLeading: return .bottomLeading
        case .bottom: return .bottom
        case .bottomTrailing: return .bottomTrailing
        }
    }
}

public enum FUHorizontalAlignment: String, CaseIterable, Identifiable, Equatable, Hashable {
    case leading
    case center
    case trailing
    
    public var id: Self { self }
    
    public var alignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

public enum FUVerticalAlignment: String, CaseIterable, Identifiable, Equatable, Hashable {
    case top
    case center
    case bottom
    
    public var id: Self { self }
    
    public var alignment: VerticalAlignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}
