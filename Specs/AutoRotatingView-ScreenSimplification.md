# AutoRotatingView: knowing the screen from the scene

Status: built on branch `screen-from-scene` (2026-10-21), unit-tested, not yet checked by folding the Duo. It builds on `FUFoldability` and `FUDeviceScreen(windowScene:)`. `movingToScreen(_:screen:sceneOrientation:deviceOrientation:)` is the pure core the tests use; the internal two-argument `onHingeScreenChange` went with the layer's hinge path. The public one went later, with `FUFoldability.hingeDidReport()`, for `onDeviceScreenChange(initial:_:)`, which reads the view's own window scene. The `deviceOrientationDidChange` guard doesn't move the state itself: the scene's geometry is stale in that notification, so it only ignores device turns until the KVO moves it.

**Later the same day:** the estimate of how the device is held after a fold (`ScreenChange`, `likelyOrientations(afterMovingTo:)`) is gone too, and `previousScreenOrientation` with it. Folding from inner landscape left with the device upside down, the system put the outer screen in landscape, and the estimate said portrait, so the tabs were laid out away from the vertical bar. A move to another screen now clears the content orientation and chooses as on appearing: the device orientation's entry, then the interface orientation's (the one the system picked), then the first allowed orientation. A change of the orientation map no longer animates either: the Top Edges example changes its maps when the hinge reports, before the interface moves, and folding from inner upside down the upright view turned on the old screen. The sections below describe the first version.

## Why

Each `AutoRotatingLayer` learns its screen from SwiftUI's `onHingeChange`, which only reports changes. A layer created after the hinge settles never hears, keeps `deviceScreen = .outer`, and on the inner screen looks its map up with the device orientation, which is a quarter turn off (Wordhord's Duo cover). The local fix seeds the screen in `windowDidChange`, on top of the hinge path.

The scene now tells everything the hinge did, at any time: whether the device folds (`FUFoldability`), and which screen the scene is on (`FUDeviceScreen(windowScene:)`). The hinge's only extra is that it reports 55 to 120 ms before the scene moves. This proposal makes the scene the layer's only source, and drops what existed to cope with the hinge.

## Proposal

**One rule:** a layer's state belongs to one screen. It's moved to another screen whenever the layer sees its scene on a screen that isn't the state's.

1. **`TurnState.screen: FUDeviceScreen`** (`.outer` on a device that doesn't fold) replaces three things:
   - `@State deviceScreen`. Every gate reads `state.screen` instead.
   - `TurnState.isAwaitingScreenLayout`. "A move is due" is `sceneScreen != state.screen`, where `sceneScreen` is `FUDeviceScreen(windowScene: window.window?.windowScene ?? .onlyApplicationScene) ?? .outer`, the same fallback `sceneOrientation` uses.
   - `@State previousScreenOrientation`. It's worked out at the move, from the state that's still the old screen's: `state.interfaceOrientation` when `state.screen == .inner`, otherwise `UIDevice.current.orientation` (continuous across a fold, in the outer screen's frame, and unfolding posts no device notification).
2. **`moveToSceneScreenIfNeeded()`**, one place that moves the state when `sceneScreen != state.screen`: sets `state.screen`, builds the `ScreenChange` from the old state, and calls today's `movingToScreen` with the scene's orientation, unanimated. The outermost layer starts the `.screen` turn there so nested layers move in the same layout pass, as today. It's called from:
   - `windowSceneGeometryDidChange` (the effective-geometry KVO, which already arrives about 2 ms before the screen's unanimated transition),
   - `interfaceWillRotate`, before anything else, in case the transition ever comes first,
   - `windowDidChange`, `onAppear` and `willEnterForeground`, which also covers a fold or unfold while the app was in the background.
3. **Drop `.onHingeScreenChange` from the layer**, and `changeScreen(to:isFirstReport:)` with it.
4. **Drop `@State hasInnerScreen`.** `hasUnallowedSystemOrientations` reads `UIDevice.current.isFoldable`. It must stay "the device folds", not "on the inner screen": it decides whether the content is hosted for `.heldStill`, and switching that rebuilds the content.
5. **First appearance** goes through the ordinary `changeOrientations(isAppearing:)` path, with `state.screen` set from the scene first. `onAppear` can do this: before the view is in a window, `onlyApplicationScene` gives the screen just as it gives the orientation. The extra first-report path goes: `changeOrientations(isChangingDeviceScreen:)`, and the first branch of `newInterfaceOrientation` (the nearest supported orientation to the device, a guess made while the scene's real orientation was at hand).
6. **`.screen` turn**: `taking(.screen)` moves a nested layer when its scene's screen isn't its state's, instead of when its own hinge flag is set.

### What it removes

| Goes | Replaced by |
| --- | --- |
| `@State deviceScreen` | `TurnState.screen` |
| `@State hasInnerScreen` | `UIDevice.current.isFoldable` |
| `@State previousScreenOrientation` | worked out from the old state at the move |
| `TurnState.isAwaitingScreenLayout` | `sceneScreen != state.screen` |
| `changeScreen(to:isFirstReport:)`, `.onHingeScreenChange` in the layer | `moveToSceneScreenIfNeeded()` |
| `isChangingDeviceScreen` on `changeOrientations` and `newInterfaceOrientation`, and the latter's first branch | the plain appearing path |
| the split between a layer that saw launch and one created later | one path for both |

`AutoRotatingLayer` loses three `@State` properties, one function and three parameters. Wordhord's late `AutoRotatingView` and one present from launch behave the same.

## What stays, and why

- **`ContentOrientationChoice.ScreenChange` and `likelyOrientations(afterMovingTo:)`.** On a new screen there's no place to keep, so the content always takes one. When the followed orientation isn't in the map, the old screen's orientation is still the best guide. The table stays an estimate, as `AutoRotatingView-SystemTurn.md` says. Only its input changes: from the old state at the move, not from a value saved at the hinge.
- **The `.screen` turn kind**, so nested layers move in the outermost's layout pass and never hand on a state from the old screen.
- **`followedOrientation`'s split.** The device orientation on the outer screen, the interface orientation on the inner, where the device orientation is a quarter turn off. It reads `state.screen`.
- **The `.outer` gates** in `deviceOrientationDidChange`, `.contentOnly` and `SystemTurnHandling`. On the inner screen the device orientation is in the wrong frame, so a `.device` or `.contentOnly` turn can't be worked out from it, and the content waits for the system's turn. They read `state.screen`. Changing `SystemTurnHandling` between `.changesAsDeviceTurns` and `.changesWithSystemTurn` doesn't change the view's structure, so following the screen there is safe.
- **The unanimated-transition guard** in `interfaceWillRotate`. After the move, the screen's transition finds the content in the scene's orientation and does nothing. A second one, as after folding in landscape, is still a turn of no duration.

## Does the fold path need the hinge's early warning?

No, as far as the measurements go. Between the hinge report and the scene's move, the hinge flag today does three things:

- **Blocks device-orientation turns.** Unfolding posts no device notification, and on the inner screen they're ignored anyway. Folding in landscape, the simulator flips the device to the other landscape for about 0.6 s. Today that flip is already handled after the scene arrives, when the flag is clear, so nothing changes.
- **Empties `heldOrientations`.** The host already skips unanimated transitions, which is all a screen move is. A real, animated turn in the gap is a turn on the old screen, and holding it is right.
- **Turns the next transition into the screen move.** Today any transition in the gap is taken as the move, even a turn still on the old screen, after which the KVO's guard fails and the real move is read as a zero-duration turn. Moving on the scene's screen fixes that case instead of guarding it.

The early warning would matter only if something needed doing before the scene moves, and nothing does: content is placed from the scene's orientation, which only exists after the move.

## Risks

- **Order of the KVO and the transition.** Measured once: KVO, then the transition 2 ms later. The move is called from both, so either order works, and it's idempotent.
- **Does the scene's `screen` change at the KVO?** `windowSceneGeometryDidChange` already relies on it. If `UIWindowScene.screen` ever lagged the geometry, the move would fall to the transition, whose guard needs `state.interfaceOrientation` to have moved already. The transition then also has to call the move first (proposal step 2).
- **Is `verticalBarEdge` set before the first layout?** Measured "set when the app starts", but not at the first `body`. If it arrived later on the folded outer screen, `isFoldable` would be false for the first layout, and a `.hold` layer whose orientations cover the outer screen's would start unhosted, then be rebuilt once. Easy to log: `isFoldable` in the first `body` of a view present at launch, folded.
- **More than one app scene.** `onlyApplicationScene` is nil, so foldability stays unknown until the layer's window arrives, and the same one-time rebuild can happen. iPhone apps rarely have more than one scene.
- **A rotation during the gap, on the old screen.** It's now taken as a real turn and animated, followed by the move. The screen turning off during a fold should hide it; it's only been reasoned about, not seen.
- **Simulator only.** Every timing here is from the Duo simulator.

## Tests

- `SystemTurnTests` builds `TurnState` with `isAwaitingScreenLayout`; it takes `screen` instead.
- New: a state on `.outer` whose scene is `.inner` moves on the next check, with `ScreenChange.from` the device orientation; a state on `.inner` moving to `.outer` takes its `from` from `interfaceOrientation`. Both as pure functions of the state, the scene's screen and orientation, and the device orientation, so they run without a simulator.
- New: a layer appearing on the inner screen follows the interface orientation (the Wordhord case), as a pure check on the appearing path.

## To check on the Duo after it's built

One session, with the Top Edges example and Wordhord's `BookView3`, logging `state.screen`, the scene's screen and the content orientation at the KVO, the transition and each device notification:

1. Launch folded, then unfold in portrait and in landscape.
2. Fold in portrait and in landscape (the landscape fold has the device flip and the second transition).
3. Launch unfolded; open a screen with a late `AutoRotatingView`; turn through all four orientations.
4. Fold and unfold with the app in the background, then bring it back.
5. Rotate while half folding, to see a turn in the gap.
