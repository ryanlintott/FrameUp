//
//  Int+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

internal extension Int {
    /// The remainder of dividing this number by a positive divisor, from 0 up to the divisor, where negative numbers count back from it.
    ///
    /// Unlike `%`, which keeps the sign of the dividend, the result is never negative.
    ///
    ///     (-1).positiveRemainder(dividingBy: 4) // 3
    ///     5.positiveRemainder(dividingBy: 4) // 1
    func positiveRemainder(dividingBy divisor: Int) -> Int {
        (self % divisor + divisor) % divisor
    }
}
