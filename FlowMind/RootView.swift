import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isVisible: $showSplash)
                    .transition(.identity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else if !appState.hasCompletedSetup {
                SetupView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedSetup)
    }
}
