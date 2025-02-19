//
//  ToggleStyle.swift
//  audition
//
//  Created by Jake Medina on 2/19/25.
//

import Foundation
import SwiftUI

struct RoundedOutlinedToggle: ToggleStyle {
    func determineStyle(on: Bool) -> some ShapeStyle{
        if on {
            return AnyShapeStyle(Color(uiColor: .systemBackground))
        } else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .foregroundStyle(determineStyle(on: configuration.isOn))
                .fontDesign(.monospaced)
                .fontWeight(.medium)
                .tracking(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    if configuration.isOn{
                        RoundedRectangle(cornerRadius: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .circular)
                            .strokeBorder(.primary, lineWidth: 2)
                    }
                }
                .animation(.default.speed(2.0))
        }
    }
}
