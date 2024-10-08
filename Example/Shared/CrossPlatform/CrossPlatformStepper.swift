//
//  CrossPlatformStepper.swift
//  ShapeUpExample
//
//  Created by Ryan Lintott on 2024-02-29.
//

import SwiftUI

struct CrossPlatformStepper<V>: View where V: Strideable, V: CVarArg {
    let label: String
    @Binding var value: V
    let minValue: V
    let maxValue: V
    let step: V.Stride
    let decimalPlaces: Int
    
    init(
        label: String,
        value: Binding<V>,
        minValue: V,
        maxValue: V,
        step: V.Stride,
        decimalPlaces: Int = 0
    ) {
        self.label = label
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.decimalPlaces = decimalPlaces
    }
    
    var format: String {
        "%.\(decimalPlaces)f"
    }
    
    var hStackStepper: some View {
        HStack {
            Text("\(label) \(String(format: format, value))")
            Button("-") { value = max(minValue, value.advanced(by: -step)) }
            Button("+") { value = min(maxValue, value.advanced(by: step)) }
        }
    }
    
    var body: some View {
        #if os(tvOS)
        hStackStepper
        #else
        if #available(watchOS 9.0, *) {
            Stepper("\(label) \(String(format: format, value))", value: $value, in: minValue...maxValue, step: step)
        } else {
            hStackStepper
        }
        #endif
    }
}

#Preview {
    CrossPlatformStepper(
        label: "Inset",
        value: .constant(2.0),
        minValue: -30,
        maxValue: 30,
        step: 10,
        decimalPlaces: 0
    )
}
