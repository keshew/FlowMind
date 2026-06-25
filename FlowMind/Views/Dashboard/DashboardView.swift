import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore
    @State private var showQuickAdd = false
    @State private var appear = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var todayTasks: [DailyTask] { taskStore.tasksForDate(Date()) }
    private var completed: [DailyTask] { taskStore.completedToday() }
    private var missed: [DailyTask] { taskStore.missedToday() }
    private var pending: [DailyTask] { taskStore.pendingToday() }
    private var completionRate: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completed.count) / Double(todayTasks.count)
    }

    var body: some View {
        ZStack {
            CFBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(greeting), \(appState.userName.isEmpty ? "Farmer" : appState.userName)!")
                                .font(.cfTitle())
                                .foregroundColor(.cfText)
                            Text("\(appState.birdType.icon) \(appState.birdCount) \(appState.birdType.rawValue)")
                                .font(.cfBody())
                                .foregroundColor(.cfTextSecondary)
                        }
                        Spacer()
                        Button(action: { showQuickAdd = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(LinearGradient.cfPrimaryGradient))
                                .shadow(color: Color.cfPrimary.opacity(0.4), radius: 8)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : -20)

                    // Today progress card
                    CFCard {
                        VStack(spacing: 14) {
                            HStack {
                                Text("Today's Progress")
                                    .font(.cfHeadline())
                                    .foregroundColor(.cfText)
                                Spacer()
                                Text(Date(), style: .date)
                                    .font(.cfCaption())
                                    .foregroundColor(.cfTextSecondary)
                            }

                            CFProgressBar(value: completionRate, color: .cfSuccess, height: 10)

                            HStack(spacing: 16) {
                                CFStatChip(label: "Total", value: "\(todayTasks.count)", color: .cfPrimary)
                                CFStatChip(label: "Done", value: "\(completed.count)", color: .cfSuccess)
                                CFStatChip(label: "Pending", value: "\(pending.count)", color: .cfAccent)
                                CFStatChip(label: "Missed", value: "\(missed.count)", color: .cfAlert)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appear)

                    // Missed tasks warning
                    if !missed.isEmpty {
                        CFCard(padding: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.cfAlert)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Missed Tasks")
                                        .font(.cfHeadline())
                                        .foregroundColor(.cfAlert)
                                    Text("\(missed.count) task(s) were not completed")
                                        .font(.cfCaption())
                                        .foregroundColor(.cfTextSecondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 18)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: appear)
                    }

                    // Upcoming tasks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Today")
                            .font(.cfHeadline())
                            .foregroundColor(.cfText)
                            .padding(.horizontal, 18)

                        if pending.isEmpty {
                            CFCard {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cfSuccess)
                                        .font(.system(size: 24))
                                    Text("All tasks completed! 🎉")
                                        .font(.cfHeadline())
                                        .foregroundColor(.cfText)
                                }
                            }
                            .padding(.horizontal, 18)
                        } else {
                            ForEach(pending.prefix(4)) { task in
                                NavigationLink(destination: TaskExecutionView(task: task)) {
                                    DashboardTaskRow(task: task)
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appear)

                    // Routine summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Routines")
                            .font(.cfHeadline())
                            .foregroundColor(.cfText)
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(routineStore.routines.filter { $0.isActive }) { routine in
                                    NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                        RoutineMiniCard(routine: routine)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appear)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appear = true }
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickCompleteView()
        }
    }
}

struct DashboardTaskRow: View {
    var task: DailyTask
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        CFCard(padding: 14) {
            HStack(spacing: 14) {
                Text(task.routineIcon)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(task.routineCategory.swiftUIColor.opacity(0.15)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.routineName)
                        .font(.cfHeadline())
                        .foregroundColor(.cfText)
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.cfTextSecondary)
                        Text(task.scheduledTime)
                            .font(.cfCaption())
                            .foregroundColor(.cfTextSecondary)
                    }
                }

                Spacer()

                CFCheckbox(isChecked: false, action: {
                    taskStore.completeTask(task.id)
                }, color: .cfSuccess)
            }
        }
    }
}

struct RoutineMiniCard: View {
    var routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(routine.icon)
                .font(.system(size: 32))
            Text(routine.name)
                .font(.cfHeadline(13))
                .foregroundColor(.cfText)
                .lineLimit(2)
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.cfTextSecondary)
                Text("\(routine.estimatedMinutes)m")
                    .font(.cfCaption(10))
                    .foregroundColor(.cfTextSecondary)
            }
        }
        .frame(width: 110)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: routine.color).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: routine.color).opacity(0.3), lineWidth: 1)
                )
        )
    }
}
