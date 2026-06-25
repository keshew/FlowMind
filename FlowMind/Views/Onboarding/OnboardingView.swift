import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            CFBackground()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1(onNext: { withAnimation { currentPage = 1 } })
                        .tag(0)
                    OnboardingPage2(onNext: { withAnimation { currentPage = 2 } })
                        .tag(1)
                    OnboardingPage3(onFinish: {
                        withAnimation {
                            appState.hasCompletedOnboarding = true
                        }
                    })
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators + navigation
                HStack(spacing: 0) {
                    // Skip
                    Button("Skip") {
                        withAnimation { appState.hasCompletedOnboarding = true }
                    }
                    .font(.cfBody())
                    .foregroundColor(.cfTextSecondary)
                    .padding(.horizontal, 24)
                    .frame(width: 100)

                    Spacer()

                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.cfPrimary : Color.cfTextTertiary)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    Spacer()

                    // Next
                    if currentPage < 2 {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.cfPrimary))
                        }
                        .padding(.horizontal, 24)
                        .frame(width: 100)
                    } else {
                        Rectangle().fill(Color.clear).frame(width: 100)
                    }
                }
                .padding(.bottom, 40)
                .padding(.top, 16)
            }
        }
    }
}

// MARK: - Page 1: Organize Daily Care (tap animation)
struct OnboardingPage1: View {
    var onNext: () -> Void
    @State private var isBursting = false
    @State private var particles: [OnboardingParticle] = []
    @State private var iconScale: CGFloat = 1.0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive illustration
            ZStack {
                // Burst particles
                ForEach(particles) { p in
                    Text(p.emoji)
                        .font(.system(size: 20))
                        .offset(p.offset)
                        .opacity(p.opacity)
                }

                // Rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.cfPrimary.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(140 + i * 60), height: CGFloat(140 + i * 60))
                        .scaleEffect(isBursting ? ringScale + CGFloat(i) * 0.3 : 1.0)
                        .opacity(isBursting ? ringOpacity : 1)
                }

                // Main icon
                ZStack {
                    Circle()
                        .fill(LinearGradient.cfPrimaryGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.cfPrimary.opacity(0.4), radius: 20)

                    Text("🐔")
                        .font(.system(size: 56))
                }
                .scaleEffect(iconScale)
                .onTapGesture {
                    burstAnimation()
                }
            }
            .frame(height: 300)

            Spacer()

            VStack(spacing: 12) {
                Text("Organize Daily Care")
                    .font(.cfDisplay(32))
                    .foregroundColor(.cfText)
                    .multilineTextAlignment(.center)

                Text("Keep all your poultry care routines in one place. Never forget a feeding or cleaning again.")
                    .font(.cfBody())
                    .foregroundColor(.cfTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Tap the chicken above! 🐔")
                    .font(.cfCaption())
                    .foregroundColor(.cfAccent)
                    .padding(.top, 4)
            }

            Spacer()

            Button("Get Started", action: onNext)
                .buttonStyle(CFPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }

    private func burstAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconScale = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
        }

        isBursting = true
        withAnimation(.easeOut(duration: 0.4)) {
            ringScale = 1.5
            ringOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isBursting = false
            ringScale = 0.8
            ringOpacity = 1
        }

        let emojis = ["⭐", "🌾", "💧", "🥚", "🌿", "✨", "🐣", "🌻"]
        particles = (0..<8).map { i in
            let angle = Double(i) * 45.0 * .pi / 180
            let dist = CGFloat.random(in: 80...140)
            return OnboardingParticle(
                emoji: emojis[i % emojis.count],
                offset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                opacity: 1.0
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                particles = particles.map { p in
                    var copy = p
                    copy.opacity = 0
                    return copy
                }
            }
        }
    }
}

struct OnboardingParticle: Identifiable {
    var id = UUID()
    var emoji: String
    var offset: CGSize
    var opacity: Double
}

// MARK: - Page 2: Build Routines (drag animation)
struct OnboardingPage2: View {
    var onNext: () -> Void
    @State private var cardOffsets: [CGSize] = [.zero, .zero, .zero]
    @State private var cardRotations: [Double] = [-8, 2, -4]
    @State private var draggedIndex: Int? = nil

    let routineItems = [
        ("🌅", "Morning Feeding", "#FF9F5A"),
        ("💧", "Water Check", "#5BA3F5"),
        ("🧹", "Coop Cleaning", "#4A90E2")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                ForEach(routineItems.indices.reversed(), id: \.self) { i in
                    let item = routineItems[i]
                    RoutineCardPreview(icon: item.0, name: item.1, color: Color(hex: item.2))
                        .offset(cardOffsets[i])
                        .rotationEffect(.degrees(cardRotations[i]))
                        .scaleEffect(draggedIndex == i ? 1.05 : 1.0)
                        .gesture(
                            DragGesture()
                                .onChanged { val in
                                    draggedIndex = i
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        cardOffsets[i] = val.translation
                                        cardRotations[i] = Double(val.translation.width / 20)
                                    }
                                }
                                .onEnded { _ in
                                    draggedIndex = nil
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        cardOffsets[i] = .zero
                                        cardRotations[i] = [-8, 2, -4][i]
                                    }
                                }
                        )
                        .zIndex(draggedIndex == i ? 10 : Double(i))
                }
            }
            .frame(height: 300)

            Spacer()

            VStack(spacing: 12) {
                Text("Build Routines")
                    .font(.cfDisplay(32))
                    .foregroundColor(.cfText)
                    .multilineTextAlignment(.center)

                Text("Create custom care routines with steps, schedules, and reminders tailored to your flock.")
                    .font(.cfBody())
                    .foregroundColor(.cfTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Drag the cards around! 👆")
                    .font(.cfCaption())
                    .foregroundColor(.cfAccent)
                    .padding(.top, 4)
            }

            Spacer()

            Button("Next", action: onNext)
                .buttonStyle(CFPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
}

struct RoutineCardPreview: View {
    var icon: String
    var name: String
    var color: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(icon).font(.system(size: 32))
            Text(name)
                .font(.cfHeadline())
                .foregroundColor(.cfText)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
                .font(.system(size: 22))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cfCard)
                .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 6)
        )
        .frame(width: 300)
    }
}

// MARK: - Page 3: Save Time (scroll parallax)
struct OnboardingPage3: View {
    var onFinish: () -> Void
    @State private var scrollOffset: CGFloat = 0
    @State private var appear = false

    let stats = [
        ("⏱️", "7 min", "Average daily care"),
        ("✅", "98%", "Task completion"),
        ("💰", "30%", "Cost savings"),
        ("🔔", "Smart", "Reminders")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Parallax scene
            ZStack {
                // Background layer (moves slower)
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        Text("🌿")
                            .font(.system(size: CGFloat(20 + i * 4)))
                            .offset(
                                x: CGFloat([-80, 90, -60, 70, -40][i]),
                                y: CGFloat([-60, -30, 10, 40, 70][i]) + scrollOffset * 0.3
                            )
                            .opacity(0.5)
                    }
                }

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(stats.indices, id: \.self) { i in
                        VStack(spacing: 6) {
                            Text(stats[i].0).font(.system(size: 28))
                            Text(stats[i].1)
                                .font(.cfHeadline(22))
                                .foregroundColor(.cfPrimary)
                            Text(stats[i].2)
                                .font(.cfCaption())
                                .foregroundColor(.cfTextSecondary)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cfCard))
                        .scaleEffect(appear ? 1.0 : 0.7)
                        .opacity(appear ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.12),
                            value: appear
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(height: 320)
            .gesture(
                DragGesture()
                    .onChanged { val in
                        scrollOffset = val.translation.height
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            scrollOffset = 0
                        }
                    }
            )

            Spacer()

            VStack(spacing: 12) {
                Text("Save Time")
                    .font(.cfDisplay(32))
                    .foregroundColor(.cfText)

                Text("Track time, costs, and resources. Let Coop Flow suggest optimizations for your daily routine.")
                    .font(.cfBody())
                    .foregroundColor(.cfTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Drag up and down on the stats! 🙌")
                    .font(.cfCaption())
                    .foregroundColor(.cfAccent)
                    .padding(.top, 4)
            }

            Spacer()

            Button("Let's Begin 🐔", action: onFinish)
                .buttonStyle(CFPrimaryButtonStyle(color: .cfSuccess))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                appear = true
            }
        }
        .onDisappear { appear = false }
    }
}
