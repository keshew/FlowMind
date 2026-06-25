import SwiftUI

struct SplashView: View {
    @Binding var isVisible: Bool

    // Phase 1: Background
    @State private var bgOpacity: Double = 0
    @State private var bgScale: CGFloat = 1.2

    // Phase 2: Thematic elements (floating feathers/eggs)
    @State private var particle1Offset: CGSize = .zero
    @State private var particle1Opacity: Double = 0
    @State private var particle2Offset: CGSize = CGSize(width: 40, height: 20)
    @State private var particle2Opacity: Double = 0
    @State private var particle3Offset: CGSize = CGSize(width: -30, height: -15)
    @State private var particle3Opacity: Double = 0
    @State private var orbitRotation: Double = 0
    @State private var sunRise: CGFloat = 80

    // Phase 3: Logo entrance
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0

    // Phase 4: Exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    // Loop control
    @State private var isAnimating: Bool = false
    @State private var loopOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // LAYER 1: Background gradient
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#1E1F2B"), Color(hex: "#26273A"), Color(hex: "#2F3045")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle radial glow
                RadialGradient(
                    colors: [Color(hex: "#4A90E2").opacity(0.2), .clear],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
            }
            .ignoresSafeArea()
            .opacity(bgOpacity)
            .scaleEffect(bgScale)

            // LAYER 2: Thematic particles - floating feathers & sun rising
            ZStack {
                // Rising sun arc
                SunriseArc()
                    .offset(y: sunRise)
                    .opacity(particle1Opacity * 0.7)

                // Orbiting elements (eggs/chicks)
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) * 60.0 + orbitRotation
                    let radius: CGFloat = 110
                    let x = radius * cos(angle * .pi / 180)
                    let y = radius * sin(angle * .pi / 180)
                    OrbitParticle(index: i)
                        .offset(x: x, y: y)
                        .opacity(particle2Opacity)
                }

                // Floating feathers
                FeatherParticle(rotation: 15, offset: CGSize(width: -120, height: -180))
                    .offset(loopOffset == 0 ? .zero : CGSize(width: -5, height: -12))
                    .opacity(particle3Opacity * 0.6)

                FeatherParticle(rotation: -25, offset: CGSize(width: 130, height: -140))
                    .offset(loopOffset == 0 ? .zero : CGSize(width: 8, height: -10))
                    .opacity(particle3Opacity * 0.5)

                FeatherParticle(rotation: 40, offset: CGSize(width: -140, height: 160))
                    .offset(loopOffset == 0 ? .zero : CGSize(width: -6, height: 14))
                    .opacity(particle3Opacity * 0.4)
            }

            // LAYER 3: Logo + Title
            VStack(spacing: 20) {
                // Logo icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#4A90E2"), Color(hex: "#5BA3F5")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 96, height: 96)
                        .shadow(color: Color(hex: "#4A90E2").opacity(0.5), radius: 20, x: 0, y: 8)

                    Text("🐔")
                        .font(.system(size: 48))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("Flow Mind")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "#4A90E2").opacity(0.5), radius: 8, x: 0, y: 4)

                    Text("Smart Poultry Care")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                        .tracking(2)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .scaleEffect(exitScale)
        .opacity(exitOpacity)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAllAnimations()
        }
    }

    private func startAnimation() {
        isAnimating = true

        // Phase 1: Background (0–0.6s)
        withAnimation(.easeOut(duration: 0.6)) {
            bgOpacity = 1.0
            bgScale = 1.0
        }

        // Phase 2: Thematic elements (0.6–1.4s)
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            particle1Opacity = 1.0
            sunRise = 0
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            particle2Opacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            particle3Opacity = 1.0
        }

        // Start orbit loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.isAnimating else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                self.orbitRotation = 360
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                self.loopOffset = 1
            }
        }

        // Phase 3: Logo entrance (1.4–2.2s)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.4)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(1.6)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // Phase 4: Exit (2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            guard self.isAnimating else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.exitScale = 1.15
                self.exitOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isVisible = false
            }
        }
    }

    private func stopAllAnimations() {
        isAnimating = false
        bgOpacity = 0
        bgScale = 1.2
        particle1Opacity = 0
        particle2Opacity = 0
        particle3Opacity = 0
        logoScale = 0.3
        logoOpacity = 0
        titleOffset = 30
        titleOpacity = 0
        orbitRotation = 0
        sunRise = 80
        loopOffset = 0
        exitScale = 1.0
        exitOpacity = 1.0
    }
}

// MARK: - Supporting Shapes

struct SunriseArc: View {
    var body: some View {
        ZStack {
            // Sunrise semicircle
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#FFC933"), Color(hex: "#FF9F5A")],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(180))

            // Rays
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(Color(hex: "#FFC933").opacity(0.5))
                    .frame(width: 2, height: 16)
                    .offset(y: -104)
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
        }
        .frame(width: 220, height: 110)
    }
}

struct OrbitParticle: View {
    var index: Int

    private var emoji: String {
        let emojis = ["🥚", "🐣", "🌾", "💧", "⭐", "🌱"]
        return emojis[index % emojis.count]
    }

    var body: some View {
        Text(emoji)
            .font(.system(size: 20))
            .opacity(0.8)
    }
}

struct FeatherParticle: View {
    var rotation: Double
    var offset: CGSize

    var body: some View {
        Text("🪶")
            .font(.system(size: 28))
            .rotationEffect(.degrees(rotation))
            .offset(offset)
    }
}
