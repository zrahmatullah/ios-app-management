import SwiftUI

public struct ConfettiParticle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var color: Color
    public var size: CGFloat
    public var rotation: Double
    public var opacity: Double
}

public struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color] = [.indigo, .pink, .purple, .yellow, .green, .orange, .blue]
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x, y: p.y)
                        .opacity(p.opacity)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
    
    private func spawnParticles(in size: CGSize) {
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<45 {
            newParticles.append(
                ConfettiParticle(
                    x: CGFloat.random(in: 20...size.width - 20),
                    y: CGFloat.random(in: -40...20),
                    color: colors.randomElement() ?? .pink,
                    size: CGFloat.random(in: 6...12),
                    rotation: Double.random(in: 0...360),
                    opacity: 1.0
                )
            )
        }
        self.particles = newParticles
        
        withAnimation(.easeOut(duration: 2.2)) {
            for i in self.particles.indices {
                self.particles[i].y += CGFloat.random(in: 300...650)
                self.particles[i].x += CGFloat.random(in: -80...80)
                self.particles[i].rotation += Double.random(in: 90...360)
                self.particles[i].opacity = 0.0
            }
        }
    }
}
