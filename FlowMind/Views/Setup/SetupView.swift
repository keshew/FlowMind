import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var birdCount: Double = 5
    @State private var selectedType: BirdType = .chicken
    @State private var userName: String = ""
    @State private var showError = false
    @State private var appear = false

    var body: some View {
        ZStack {
            CFBackground()

            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Welcome!")
                            .font(.cfDisplay())
                            .foregroundColor(.cfText)
                        Text("Let's set up your flock")
                            .font(.cfBody())
                            .foregroundColor(.cfTextSecondary)
                    }
                    .padding(.top, 60)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appear)

                    // Your name
                    CFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Your Name", systemImage: "person.fill")
                                .font(.cfHeadline())
                                .foregroundColor(.cfTextSecondary)

                            TextField("Enter your name", text: $userName)
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appear)

                    // Bird count
                    CFCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Number of Birds", systemImage: "number")
                                .font(.cfHeadline())
                                .foregroundColor(.cfTextSecondary)

                            HStack {
                                Text("\(Int(birdCount))")
                                    .font(.cfDisplay(48))
                                    .foregroundColor(.cfPrimary)
                                    .frame(width: 80)

                                Slider(value: $birdCount, in: 1...200, step: 1)
                                    .accentColor(.cfPrimary)
                            }

                            HStack {
                                ForEach([1, 5, 10, 25, 50, 100], id: \.self) { n in
                                    Button("\(n)") {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            birdCount = Double(n)
                                        }
                                    }
                                    .font(.cfCaption())
                                    .foregroundColor(Int(birdCount) == n ? .cfBg : .cfTextSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Int(birdCount) == n ? Color.cfPrimary : Color.cfCardLight)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appear)

                    // Bird type
                    CFCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Bird Type", systemImage: "bird.fill")
                                .font(.cfHeadline())
                                .foregroundColor(.cfTextSecondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(BirdType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedType = type
                                        }
                                    }) {
                                        VStack(spacing: 6) {
                                            Text(type.icon)
                                                .font(.system(size: 28))
                                            Text(type.rawValue)
                                                .font(.cfCaption(10))
                                                .foregroundColor(selectedType == type ? .cfText : .cfTextSecondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedType == type ? Color.cfPrimary : Color.cfCardLight)
                                                .shadow(color: selectedType == type ? Color.cfPrimary.opacity(0.3) : .clear, radius: 6)
                                        )
                                    }
                                    .scaleEffect(selectedType == type ? 1.05 : 1.0)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appear)

                    if showError {
                        Text("Please enter your name")
                            .font(.cfCaption())
                            .foregroundColor(.cfAlert)
                    }

                    Button(action: saveSetup) {
                        HStack {
                            Text("Let's Go!")
                            Text(selectedType.icon)
                        }
                    }
                    .buttonStyle(CFPrimaryButtonStyle(color: .cfSuccess))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: appear)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appear = true
            }
        }
    }

    private func saveSetup() {
        guard !userName.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { showError = true }
            return
        }
        appState.userName = userName
        appState.birdCount = Int(birdCount)
        appState.birdType = selectedType
        withAnimation {
            appState.hasCompletedSetup = true
        }
    }
}
