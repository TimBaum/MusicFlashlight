//
//  Circle Animation.swift
//  Music Flashlight
//
//  Created by Tim Baum on 08.06.22.
//

import SwiftUI
import UIKit

// MARK: Polygon with lines edge to edge
struct PolygonAnimation: View {
    @Binding public var sides: Double
    @State private var scale: Double = 1.0
    
    var body: some View {
        VStack {
            PolygonShape(sides: sides, scale: scale)
                .stroke(Color.white, lineWidth: (sides < 3) ? 10 : ( sides < 7 ? 5 : 2))
                .padding(10)
                .animation(.easeOut(duration: 1.25))
                .layoutPriority(0)
        }
    }
}

struct AnimationPreview_Previews: PreviewProvider {
    static var previews: some View {
        PolygonAnimation(sides: .constant(4.0))
    }
}


struct PolygonShape: Shape {
    var sides: Double
    var scale: Double
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(sides, scale) }
        set {
            sides = newValue.first
            scale = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        // hypotenuse
        let h = Double(min(rect.size.width, rect.size.height)) / 2.0 * scale
        
        // center
        let c = CGPoint(x: rect.size.width / 2.0, y: rect.size.height / 2.0)
        
        var path = Path()
        
        let extra: Int = sides != Double(Int(sides)) ? 1 : 0
        
        var vertex: [CGPoint] = []
        
        for i in 0..<Int(sides) + extra {
            
            let angle = (Double(i) * (360.0 / sides)) * (Double.pi / 180)
            
            // Calculate vertex
            let pt = CGPoint(x: c.x + CGFloat(cos(angle) * h), y: c.y + CGFloat(sin(angle) * h))
            
            vertex.append(pt)
            
            if i == 0 {
                path.move(to: pt) // move to first vertex
            } else {
                path.addLine(to: pt) // draw line to next vertex
            }
        }
        
        path.closeSubpath()
        
        // Draw vertex-to-vertex lines
        drawVertexLines(path: &path, vertex: vertex, n: 0)
        
        return path
    }
    
    func drawVertexLines(path: inout Path, vertex: [CGPoint], n: Int) {
        
        if (vertex.count - n) < 3 { return }
        
        for i in (n+2)..<min(n + (vertex.count-1), vertex.count) {
            path.move(to: vertex[n])
            path.addLine(to: vertex[i])
        }
        
        drawVertexLines(path: &path, vertex: vertex, n: n+1)
    }
}
