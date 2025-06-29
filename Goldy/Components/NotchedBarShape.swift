//
//  NotchedBarShape.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

/// A shape that forms a bottom bar with a top-center arc (notch).
/// Also includes optional corner rounding on the left and right edges.
struct NotchedBarShape: Shape {
    var notchRadius: CGFloat
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let barTopY = notchRadius
        let barBottomY = rect.height
        
        // Bottom-left corner
        path.move(to: CGPoint(x: cornerRadius, y: barBottomY))
        // Left corner rounding
        path.addQuadCurve(
            to: CGPoint(x: 0, y: barBottomY - cornerRadius),
            control: CGPoint(x: 0, y: barBottomY)
        )
        // Move up left edge
        path.addLine(to: CGPoint(x: 0, y: barTopY + cornerRadius))
        // Top-left corner rounding
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: barTopY),
            control: CGPoint(x: 0, y: barTopY)
        )
        
        // Arc over the top center
        let centerX = rect.midX
        path.addLine(to: CGPoint(x: centerX - notchRadius, y: barTopY))
        path.addArc(
            center: CGPoint(x: centerX, y: barTopY),
            radius: notchRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Top-right corner rounding
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: barTopY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: barTopY + cornerRadius),
            control: CGPoint(x: rect.width, y: barTopY)
        )
        // Move down right edge
        path.addLine(to: CGPoint(x: rect.width, y: barBottomY - cornerRadius))
        // Bottom-right corner rounding
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: barBottomY),
            control: CGPoint(x: rect.width, y: barBottomY)
        )
        // Close at bottom-left
        path.addLine(to: CGPoint(x: cornerRadius, y: barBottomY))
        
        return path
    }
}
