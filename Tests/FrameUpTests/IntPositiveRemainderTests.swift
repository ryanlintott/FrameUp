//
//  IntPositiveRemainderTests.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-20.
//

import Testing
@testable import FrameUp

struct IntPositiveRemainderTests {
    @Test(arguments: [
        (0, 4, 0), (3, 4, 3), (4, 4, 0), (5, 4, 1), (-1, 4, 3), (-4, 4, 0), (-5, 4, 3), (-1, 2, 1), (7, 3, 1)
    ])
    func isNeverNegative(value: Int, divisor: Int, expected: Int) {
        #expect(value.positiveRemainder(dividingBy: divisor) == expected)
    }
}
