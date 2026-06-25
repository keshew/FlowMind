import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                RoutineListView()
                    .tag(1)
                TodayTasksView()
                    .tag(2)
                AnalyticsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            CFTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            taskStore.generateTasks(for: Date(), from: routineStore.routines)
        }
    }
}

struct CFTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var taskStore: TaskStore

    private let items: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("arrow.triangle.2.circlepath", "Routines"),
        ("checkmark.circle.fill", "Tasks"),
        ("chart.bar.fill", "Analytics"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: items[i].icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(selectedTab == i ? .cfPrimary : .cfTextTertiary)
                                .scaleEffect(selectedTab == i ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                            // Badge for missed tasks
                            if i == 2 && taskStore.missedToday().count > 0 {
                                Circle()
                                    .fill(Color.cfAlert)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 14, y: -10)
                            }
                        }

                        Text(items[i].label)
                            .font(.cfCaption(10))
                            .foregroundColor(selectedTab == i ? .cfPrimary : .cfTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == i ?
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cfPrimary.opacity(0.12))
                            .padding(.horizontal, 4) : nil
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.cfCard)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
