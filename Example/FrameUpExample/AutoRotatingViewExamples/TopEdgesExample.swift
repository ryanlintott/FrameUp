//
//  TopEdgesExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-16.
//

import FrameUp
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.abetterwaytodo.FrameUpExample", category: "TopEdges")

#if os(iOS)
/// A tab view whose top faces away from the system's vertical toolbar, so its tab bar sits beside the toolbar: on the iPhone Duo's outer screen, beside the column in every orientation, and on its inner screen, beside the column in landscape and along the bottom in portrait. On an iPhone that doesn't fold, the tab bar is along the bottom in portrait and away from the Dynamic Island in landscape.
///
/// The frame is fixed to the device, and the tab view turns inside it with the system's timing. A red strip runs along the tab view's top, and its tab bar is yellow; both reach out past the tab view to cover the gaps. A dashed line runs along its safe area. The information in the middle is in an `AutoRotatingView` of its own that allows every orientation, so it stays upright whichever way the tab view faces.
@available(iOS 17, *)
struct TopEdgesExample: View {
    @State private var isPresented: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The tab view's top, the red strip, faces away from the system's vertical toolbar, so its tab bar sits beside it. The dictionary is chosen for each screen and known before every turn. The frame around it stays fixed to the device. The red strip and the yellow tab bar reach past the tab view's edges to cover the screen during a turn.")
            
            Button("Show Tabs") {
                isPresented = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.callout)
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle("Top Edges")
        .fullScreenCover(isPresented: $isPresented) {
            TopEdgesProbe(isPresented: $isPresented)
        }
    }
}

/// Where the tab view's top points, as the user sees it, in each orientation.
/// The screens the example picks a dictionary for.
enum TopEdgesScreen {
    /// An iPhone that doesn't fold.
    case iPhone
    case foldableOuter
    case foldableInner
    /// The inner screen's left split window, where the column is on the left.
    case foldableInnerLeftWindow
    
    /// - Parameters:
    ///   - hingeScreen: The screen of a foldable iPhone, or nil on one that doesn't fold.
    ///   - systemBar: The system's bar, measured outside the rotation. Only a window change moves the column to the left, never a turn, so the dictionary changes then.
    init(hingeScreen: FUDeviceScreen?, systemBar: SystemBarGeometry?) {
        switch hingeScreen {
        case .outer: self = .foldableOuter
        case .inner: self = systemBar?.kind == .verticalToolbar && systemBar?.edge == .leading ? .foldableInnerLeftWindow : .foldableInner
        case nil: self = .iPhone
        }
    }
    
    /// Where the tab view's top points, as the user sees it, in each orientation: away from the system's vertical toolbar, measured in the iPhone Duo simulator (iOS 27.1). It has to be known before each turn, since the toolbar's new edge arrives after the turn has started.
    var topEdges: [FUInterfaceOrientation: Edge] {
        switch self {
        /// Held in device portrait, so the tab bar stays on the device's bottom edge, away from the Dynamic Island in landscape. The interface doesn't turn upside down, so that's left out.
        case .iPhone: [.portrait: .top, .landscapeRight: .trailing, .landscapeLeft: .leading]
        /// The column is on the right in portrait and landscape right, and on the left in landscape left: it follows the camera in landscape. The interface doesn't turn upside down, so the column stays wherever the last orientation left it, and upside down is left out to keep the content with it.
        case .foldableOuter: [.portrait: .leading, .landscapeRight: .leading, .landscapeLeft: .trailing]
        /// The column is on the right in either landscape, and there's none in portrait, where the tab bar is along the bottom.
        case .foldableInner: [.portrait: .top, .landscapeRight: .leading, .landscapeLeft: .leading, .portraitUpsideDown: .top]
        /// The left split window's column is on the left in either landscape.
        case .foldableInnerLeftWindow: [.portrait: .top, .landscapeRight: .trailing, .landscapeLeft: .trailing, .portraitUpsideDown: .top]
        }
    }
    
    /// The orientations the views that stay upright turn to. The app doesn't support upside down, so they leave it out, except on a foldable iPhone's inner screen, where the system turns the interface to every orientation.
    var uprightOrientations: [FUInterfaceOrientation] {
        switch self {
        case .foldableInner, .foldableInnerLeftWindow: FUInterfaceOrientation.allCases
        case .iPhone, .foldableOuter: [.portrait, .landscapeLeft, .landscapeRight]
        }
    }
    
    /// The edge of the system's vertical toolbar the dictionary expects in an orientation, or nil for none: opposite where the tab view's top points.
    func expectedToolbarEdge(_ orientation: FUInterfaceOrientation) -> HorizontalEdge? {
        switch topEdges[orientation] {
        case .leading: .trailing
        case .trailing: .leading
        default: nil
        }
    }
}

/// The tab view in `AutoRotatingView(topEdges:)`, shown on launch with the `-FUTopEdgesScreen` launch argument for turning and folding the device without any navigation.
@available(iOS 17, *)
struct TopEdgesProbe: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        TopEdgesRotation(isPresented: $isPresented)
            /// Measured outside the rotation; the tab view reads it turned into its own frame.
            .measuresSystemBarGeometry()
    }
}

@available(iOS 17, *)
private struct TopEdgesRotation: View {
    @Binding var isPresented: Bool
    /// The screen of a foldable iPhone, or nil on one that doesn't fold.
    @State private var hingeScreen: FUDeviceScreen? = nil
    /// The system's bar outside the rotation.
    @Environment(\.systemBarGeometry) private var systemBar
    
    var screen: TopEdgesScreen {
        TopEdgesScreen(hingeScreen: hingeScreen, systemBar: systemBar)
    }
    
    var body: some View {
        AutoRotatingView(topEdges: screen.topEdges) {
            PresentedTabs(isPresented: $isPresented, screen: screen)
                .geometryProbe("inside")
        }
        .geometryProbe("outside")
        .toolbarEdgeCheck(screen)
        .onHingeScreenChange { hingeScreen = $0 }
    }
}

extension View {
    /// Logs whether the system's vertical toolbar, once it has settled, is where the screen's dictionary expects it.
    func toolbarEdgeCheck(_ screen: TopEdgesScreen) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.85)
        return modifier(ToolbarEdgeCheck(screen: screen))
        #else
        return self
        #endif
    }
}

#if canImport(SwiftUICore, _version: 8.0.85)
private struct ToolbarEdgeCheck: ViewModifier {
    let screen: TopEdgesScreen
    
    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.modifier(Reader(screen: screen))
        } else {
            content
        }
    }
    
    @available(iOS 27.1, *)
    private struct Reader: ViewModifier {
        let screen: TopEdgesScreen
        @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
        /// Changes with every turn of the device, so the check runs again even when nothing on the screen changes size, as between the two landscapes.
        @State private var deviceTurns = 0
        
        /// The interface's orientation, named as `AutoRotatingView` names it.
        var interfaceOrientation: FUInterfaceOrientation? {
            switch (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation {
            case .portrait: .portrait
            case .portraitUpsideDown: .portraitUpsideDown
            case .landscapeLeft: .landscapeRight
            case .landscapeRight: .landscapeLeft
            default: nil
            }
        }
        
        /// The orientation as `AutoRotatingView` names it: the device's on the outer screen, and the interface's on the inner screen.
        var orientation: FUInterfaceOrientation? {
            if screen == .foldableInner {
                return interfaceOrientation
            }
            switch UIDevice.current.orientation {
            case .portrait: return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft: return .landscapeLeft
            case .landscapeRight: return .landscapeRight
            default: return nil
            }
        }
        
        func body(content: Content) -> some View {
            content
                                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    deviceTurns += 1
                }
                .task(id: "\(toolbarVerticalEdge.map { "\($0)" } ?? "nil") \(screen) \(deviceTurns)") {
                    /// The edge and the orientation settle a moment after a turn or a fold.
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled, let orientation else { return }
                    guard screen.topEdges[orientation] != nil else {
                        logger.info("toolbar check skipped screen \(String(describing: screen), privacy: .public) orientation \(String(describing: orientation), privacy: .public): not in the dictionary, so the content stays put")
                        return
                    }
                    let expected = screen.expectedToolbarEdge(orientation)
                    /// `toolbarVerticalEdge` names the interface's edge. Where the interface hasn't turned with the device, as when an iPhone is held upside down, the user sees it the other way round.
                    let isInterfaceUpsideDown = switch (interfaceOrientation, orientation) {
                    case (.portrait, .portraitUpsideDown), (.portraitUpsideDown, .portrait), (.landscapeLeft, .landscapeRight), (.landscapeRight, .landscapeLeft): true
                    default: false
                    }
                    let measured = isInterfaceUpsideDown ? toolbarVerticalEdge.map { $0 == .leading ? HorizontalEdge.trailing : .leading } : toolbarVerticalEdge
                    let result = expected == measured ? "ok" : "MISMATCH"
                    logger.info("toolbar check \(result, privacy: .public) screen \(String(describing: screen), privacy: .public) orientation \(String(describing: orientation), privacy: .public) expected \(expected.map { "\($0)" } ?? "nil", privacy: .public) measured \(measured.map { "\($0)" } ?? "nil", privacy: .public)")
                }
        }
    }
}
#endif

extension View {
    /// Logs the size, safe area, reserved regions and the system's vertical toolbar edge as this view sees them, whenever they change, to compare them inside and outside a rotation.
    func geometryProbe(_ label: String) -> some View {
        modifier(GeometryProbe(label: label))
    }
}

private struct GeometryProbe: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        /// `reservedRegions` and `toolbarVerticalEdge` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content.modifier(Reader(label: label))
        } else {
            content
        }
        #else
        content
        #endif
    }
    
    #if canImport(SwiftUICore, _version: 8.0.85)
    @available(iOS 27.1, *)
    private struct Reader: ViewModifier {
        let label: String
        @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
        @Environment(\.autoRotatingOrientation) private var orientation
        
        func body(content: Content) -> some View {
            let edge = toolbarVerticalEdge.map { "\($0)" } ?? "nil"
            let presented = orientation.map { "\($0)" } ?? "none"
            content
                .onGeometryChange(for: String.self) { proxy in
                    let occlusion = proxy.reservedRegions(kind: .occlusion).map { Self.text($0.frame) }
                    let division = proxy.reservedRegions(kind: .division, options: .includeInactive).map { Self.text($0.frame) }
                    let insets = proxy.safeAreaInsets
                    return "size \(Int(proxy.size.width))x\(Int(proxy.size.height)) safe t\(Int(insets.top)) l\(Int(insets.leading)) b\(Int(insets.bottom)) r\(Int(insets.trailing)) occlusion \(occlusion) division \(division)"
                } action: { geometry in
                    logger.info("probe \(label, privacy: .public) presented \(presented, privacy: .public) toolbarEdge \(edge, privacy: .public) scene \(FUInterfaceOrientationName.scene, privacy: .public) device \(UIDevice.current.orientation.rawValue, privacy: .public) \(geometry, privacy: .public)")
                }
                /// The environment can change without the geometry changing.
                .onChange(of: edge + " " + presented) {
                    logger.info("probe \(label, privacy: .public) presented \(presented, privacy: .public) toolbarEdge \(edge, privacy: .public) scene \(FUInterfaceOrientationName.scene, privacy: .public) (environment only)")
                }
        }
        
        static func text(_ rect: CGRect) -> String {
            "(\(Int(rect.minX)),\(Int(rect.minY)) \(Int(rect.width))x\(Int(rect.height)))"
        }
    }
    #endif
}

@available(iOS 17, *)
private struct PresentedTabs: View {
    @Binding var isPresented: Bool
    let screen: TopEdgesScreen
    /// The system's bar, turned into the tab view's frame. The tab view's top faces away from it, so it should always be on the bottom edge.
    @Environment(\.systemBarGeometry) private var systemBar
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var systemBarDescription: String {
        guard let systemBar else { return "nil" }
        return "\(systemBar.kind) edge \(systemBar.edge) depth \(Int(systemBar.depth)) usable \(Int(systemBar.usableStart))-\(Int(systemBar.usableEnd)) reserved \(Int(systemBar.reservedDepth))"
    }
    
    var body: some View {
        GeometryReader { proxy in
            tabs
                .task(id: systemBarDescription) {
                    /// Logged once the bar has settled after a turn or a fold.
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    let result = systemBar?.edge == .bottom ? "ok" : "MISMATCH"
                    logger.info("system bar \(result, privacy: .public) inside \(systemBarDescription, privacy: .public) presented \(orientation.map { "\($0)" } ?? "none", privacy: .public)")
                }
                .onChange(of: orientation, initial: true) {
                    logger.info("presented \(orientation.map { "\($0)" } ?? "none", privacy: .public) size \(proxy.size.width, privacy: .public)x\(proxy.size.height, privacy: .public) scene \(FUInterfaceOrientationName.scene, privacy: .public) device \(UIDevice.current.orientation.rawValue, privacy: .public)")
                }
        }
    }
    
    @State private var tab = "book"
    
    var tabs: some View {
        TabView(selection: $tab) {
            ForEach(Self.items, id: \.tab) { item in
                /// The information turns to stay upright, whichever way the tab view faces, in the orientations the screen supports. Elsewhere it stays as it was.
                AutoRotatingView(screen.uprightOrientations) {
                    VStack(spacing: 12) {
                        Image(systemName: item.tab)
                            .font(.system(size: 60))
                        DeviceOrientationInfo(topEdges: screen.topEdges)
                        Button("Close") {
                            isPresented = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .border(.yellow, width: 2)
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(item.tab)
            }
        }
        .overlay {
            EdgeOutlines()
        }
        /// A menu placed by hand where the system's bar is, which, with the tab view's top facing away from it, is along the tab view's bottom. Each item turns on its own to stay upright.
        .systemBarInset { bar in
            SystemBarTabs(bar: bar, tab: $tab, orientations: screen.uprightOrientations)
        }
        .onChange(of: tab) {
            logger.info("selected \(tab, privacy: .public)")
        }
    }
    
    /// Titles as long as Wordhord's, to see whether a turned item fits its cell.
    static let items: [(tab: String, title: String)] = [
        ("book", "Wordhord"),
        ("building.columns", "Categories"),
        ("star", "Favourites"),
        ("scroll", "About")
    ]
}

/// The tab menu in the system's bar: spread along a bar at the bottom, and grouped at the user's bottom end of a vertical toolbar, as the system groups its own, with the items listed from the user's top or leading end.
@available(iOS 17, *)
private struct SystemBarTabs: View {
    let bar: SystemBarGeometry
    @Binding var tab: String
    let orientations: [FUInterfaceOrientation]
    @Environment(\.interfaceTurn) private var turn
    @Environment(\.layoutDirection) private var layoutDirection
    
    /// The length of each item's slot in the system's vertical toolbar: the system's natural item height, as FrameUp's own vertical bar uses.
    static let slotLength: CGFloat = 50
    /// How far the system keeps its grouped items from the window's bottom edge (measured on the iPhone Duo).
    static let groupMargin: CGFloat = 24
    /// How far the bar's colour reaches past the container.
    static let extent: CGFloat = 2000
    
    /// True when the bar runs along this view's top or bottom.
    var isHorizontal: Bool {
        bar.edge == .top || bar.edge == .bottom
    }
    
    /// True when the bar's start, its leading or top end, isn't where the user starts reading: the top of the interface, or its leading end.
    var isReversed: Bool {
        let startSide = turn.interfaceEdge(of: isHorizontal ? .leading : .top, layoutDirection: layoutDirection)
        return startSide != .top && startSide != .leading
    }
    
    /// Where the items group in a vertical toolbar: the end of the bar at the bottom of the interface.
    var groupAlignment: Alignment {
        switch turn.localEdge(of: .bottom, layoutDirection: layoutDirection) {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }
    
    /// Away from the container's edge, so the menu sits clear of the safe area the bar includes, such as the Home indicator.
    var innerAlignment: Alignment {
        switch bar.edge {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }
    
    var items: [TabMenuItem<String>] {
        let items = PresentedTabs.items.map { TabMenuItem(LocalizedStringKey($0.title), systemImage: $0.tab, tab: $0.tab) }
        return isReversed ? items.reversed() : items
    }
    
    var body: some View {
        /// A horizontal `TabMenu` pads each item 10 points either side, so a slot needs that much more length.
        let groupLength = (Self.slotLength + 20) * CGFloat(items.count)
        let isGrouped = bar.kind == .verticalToolbar
        TabMenu(selection: $tab, items: items)
            .tabMenuItemStyle(UprightTabMenuItemStyle(orientations: orientations, base: .masked { isSelected in
                isSelected ? Color.accentColor : Color.secondary
            }))
            .onTabMenuItemReselect("Reselect") {
                logger.info("reselected \(tab, privacy: .public)")
            }
            /// In the system's vertical toolbar the menu runs across the toolbar's full depth, which is each turned item's width. Along the bottom it keeps the system's 50 points, clear of the Home indicator.
            .tabMenuFillsHeight(isGrouped)
            .frame(width: isGrouped && isHorizontal ? groupLength : nil, height: isGrouped && !isHorizontal ? groupLength : nil)
            .padding(Edge.Set(turn.localEdge(of: .bottom, layoutDirection: layoutDirection)), isGrouped ? Self.groupMargin : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isGrouped ? groupAlignment : innerAlignment)
            /// The part of the bar clear of the camera, the status items and the hinge.
            .padding(isHorizontal ? .leading : .top, bar.usableStart)
            .padding(isHorizontal ? .trailing : .bottom, bar.usableEnd)
            .background {
                /// Reaches far out past the container's edge and along it, like the red strip, so it covers anything behind the content during a turn.
                Color.yellow
                    .padding(Edge.Set(bar.edge), -Self.extent)
                    .padding(isHorizontal ? .horizontal : .vertical, -Self.extent)
                    .allowsHitTesting(false)
            }
    }
}

/// Draws each item with another style, in an `AutoRotatingView` of its own, so it stays upright to the user whichever way the menu faces, in the orientations it allows.
private struct UprightTabMenuItemStyle<Base: TabMenuItemStyle>: TabMenuItemStyle {
    /// The orientations the item turns to.
    let orientations: [FUInterfaceOrientation]
    let base: Base
    
    func makeBody(configuration: Configuration) -> some View {
        AutoRotatingView(orientations) {
            base.makeBody(configuration: configuration)
        }
    }
}

/// The orientation of the device, read from the `AutoRotatingView` the information is in, which allows every orientation, and where the tab view's top points in it.
private struct DeviceOrientationInfo: View {
    let topEdges: [FUInterfaceOrientation: Edge]
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var body: some View {
        VStack(spacing: 4) {
            Text(orientation.map { "\($0)" } ?? "none")
                .font(.title2.monospaced())
            Text("up: \(orientation.flatMap { topEdges[$0] }.map { "\($0)" } ?? "none")")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

/// A red strip along the top of the full area, reaching far out past it so it covers anything behind the content during a turn, and a dashed line along the safe area.
private struct EdgeOutlines: View {
    /// How far the strip reaches inside the full area.
    let thickness: CGFloat = 24
    /// How far the strip reaches out past the full area, along it and away from it.
    let extent: CGFloat = 2000
    
    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                Rectangle().fill(.red)
                    .frame(height: thickness + extent)
                    .padding(.horizontal, -extent)
                    .offset(y: -extent)
            }
            .ignoresSafeArea()
            .overlay {
                Rectangle()
                    .stroke(.primary, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            }
            .allowsHitTesting(false)
    }
}

@available(iOS 17, *)
private enum FUInterfaceOrientationName {
    @MainActor static var scene: String {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene.map { "\($0.effectiveGeometry.interfaceOrientation.rawValue)" } ?? "none"
    }
}

#Preview {
    if #available(iOS 17, *) {
        NavigationView {
            TopEdgesExample()
        }
    }
}
#endif
