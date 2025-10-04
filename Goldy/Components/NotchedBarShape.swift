//
//  NotchedBarShape.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

struct NotchedBarShape: Shape {
    var notchRadius: CGFloat
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let barTopY = notchRadius
        let barBottomY = rect.height
        
        path.move(to: CGPoint(x: cornerRadius, y: barBottomY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: barBottomY - cornerRadius),
            control: CGPoint(x: 0, y: barBottomY)
        )
        path.addLine(to: CGPoint(x: 0, y: barTopY + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: barTopY),
            control: CGPoint(x: 0, y: barTopY)
        )
        
        let centerX = rect.midX
        path.addLine(to: CGPoint(x: centerX - notchRadius, y: barTopY))
        path.addArc(
            center: CGPoint(x: centerX, y: barTopY),
            radius: notchRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: barTopY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: barTopY + cornerRadius),
            control: CGPoint(x: rect.width, y: barTopY)
        )
        path.addLine(to: CGPoint(x: rect.width, y: barBottomY - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: barBottomY),
            control: CGPoint(x: rect.width, y: barBottomY)
        )
        path.addLine(to: CGPoint(x: cornerRadius, y: barBottomY))
        
        return path
    }
}
