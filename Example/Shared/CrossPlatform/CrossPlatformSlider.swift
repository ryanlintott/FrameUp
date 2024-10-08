//
//  CrossPlatformSlider.swift
//  ShapeUpExample
//
//  Created by Ryan Lintott on 2024-02-29.
//

import SwiftUI

struct CrossPlatformSlider<V>: View where V: BinaryFloatingPoint, V: CVarArg, V.Stride: BinaryFloatingPoint {
    let label: String
    @Binding var value: V
    let minValue: V
    let maxValue: V
    let step: V.Stride
    let decimalPlaces: Int
    let labelPrefix: Bool
    
    init(
        label: String,
        value: Binding<V>,
        minValue: V,
        maxValue: V,
        step: V.Stride,
        decimalPlaces: Int = 0,
        labelPrefix: Bool = false
    ) {
        self.label = label
        self._value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.decimalPlaces = decimalPlaces
        self.labelPrefix = labelPrefix
    }
    
    var format: String {
        "%.\(decimalPlaces)f"
    }
    
    var body: some View {
        #if os(tvOS)
        HStack {
            Text("\(label) \(String(format: format, value))")
            Button("-") { value = max(minValue, value.advanced(by: -step)) }
            Button("+") { value = min(maxValue, value.advanced(by: step)) }
        }
        #else
        Slider(value: $value, in: minValue...maxValue) {
            Text(label)
        } minimumValueLabel: {
            Text("\(labelPrefix ? "\(label): " : "")\(String(format: format, minValue))")
        } maximumValueLabel: {
            Text(String(format: format, maxValue))
        }
        #endif
    }
}

#Preview {
    CrossPlatformSlider(
        label: "Inset",
        value: .constant(2.0),
        minValue: -30,
        maxValue: 30,
        step: 10,
        decimalPlaces: 0,
        labelPrefix: true
    )
    .padding()
}
