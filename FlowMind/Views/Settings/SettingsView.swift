import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var photoStore: PhotoStore
    @EnvironmentObject var noteStore: NoteStore

    @State private var showResetAlert = false
    @State private var showBackupAlert = false
    @State private var backupDone = false
    @State private var showBirdSetup = false

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile
                        CFCard(padding: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.cfPrimaryGradient)
                                        .frame(width: 60, height: 60)
                                    Text(appState.birdType.icon)
                                        .font(.system(size: 30))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appState.userName.isEmpty ? "Farmer" : appState.userName)
                                        .font(.cfTitle(20))
                                        .foregroundColor(.cfText)
                                    Text("\(appState.birdCount) \(appState.birdType.rawValue)")
                                        .font(.cfBody())
                                        .foregroundColor(.cfTextSecondary)
                                }
                                Spacer()
                                Button(action: { showBirdSetup = true }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.cfPrimary)
                                        .frame(width: 36, height: 36)
                                        .background(Circle().fill(Color.cfPrimary.opacity(0.15)))
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Appearance
                        SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
                            VStack(spacing: 0) {
                                SettingsRow(label: "Theme") {
                                    Picker("Theme", selection: $appState.themeMode) {
                                        Text("System").tag("system")
                                        Text("Dark").tag("dark")
                                        Text("Light").tag("light")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 200)
                                }
                            }
                        }

                        // Notifications
                        SettingsSection(title: "Notifications", icon: "bell.fill") {
                            VStack(spacing: 0) {
                                SettingsRow(label: "Enable Notifications") {
                                    Toggle("", isOn: $appState.notificationsEnabled)
                                        .tint(.cfSuccess)
                                        .onChange(of: appState.notificationsEnabled) { enabled in
                                            if enabled {
                                                notificationManager.requestPermission { granted in
                                                    if granted {
                                                        notificationManager.scheduleAll(
                                                            tasks: taskStore.pendingToday(),
                                                            minutesBefore: appState.reminderMinutesBefore
                                                        )
                                                    } else {
                                                        appState.notificationsEnabled = false
                                                    }
                                                }
                                            } else {
                                                notificationManager.cancelAll()
                                            }
                                        }
                                }
                                if appState.notificationsEnabled {
                                    Divider().background(Color.cfTextTertiary)
                                    SettingsRow(label: "Remind before (min)") {
                                        Stepper("\(appState.reminderMinutesBefore) min",
                                                value: $appState.reminderMinutesBefore, in: 5...60, step: 5)
                                            .foregroundColor(.cfText)
                                            .onChange(of: appState.reminderMinutesBefore) { mins in
                                                if appState.notificationsEnabled {
                                                    notificationManager.scheduleAll(
                                                        tasks: taskStore.pendingToday(),
                                                        minutesBefore: mins
                                                    )
                                                }
                                            }
                                    }
                                }
                                Divider().background(Color.cfTextTertiary)
                                SettingsRow(label: "Notification Status") {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(notificationManager.isAuthorized ? Color.cfSuccess : Color.cfAlert)
                                            .frame(width: 8, height: 8)
                                        Text(notificationManager.isAuthorized ? "Authorized" : "Not authorized")
                                            .font(.cfCaption())
                                            .foregroundColor(.cfTextSecondary)
                                    }
                                }
                            }
                        }

                        // Tracking
                        SettingsSection(title: "Tracking", icon: "chart.bar.fill") {
                            VStack(spacing: 0) {
                                SettingsRow(label: "Cost Tracking") {
                                    Toggle("", isOn: $appState.showCostTracking).tint(.cfSuccess)
                                }
                                Divider().background(Color.cfTextTertiary)
                                SettingsRow(label: "Automation Mode") {
                                    Toggle("", isOn: $appState.autoModeEnabled).tint(.cfAccent)
                                }
                                Divider().background(Color.cfTextTertiary)
                                SettingsRow(label: "Week starts on") {
                                    Toggle("Monday", isOn: $appState.weekStartsMonday)
                                        .tint(.cfPrimary)
                                        .foregroundColor(.cfTextSecondary)
                                }
                            }
                        }

                        // Quick links
                        SettingsSection(title: "More", icon: "ellipsis.circle.fill") {
                            VStack(spacing: 0) {
                                NavigationLink(destination: NotificationsSettingsView()) {
                                    SettingsLink(label: "Notification Schedule", icon: "calendar.badge.clock")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: PhotoLogView()) {
                                    SettingsLink(label: "Photo Log", icon: "photo.stack.fill")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: NotesView()) {
                                    SettingsLink(label: "Notes", icon: "square.and.pencil")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: AlertsView()) {
                                    SettingsLink(label: "Alerts", icon: "exclamationmark.triangle.fill")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: CalendarView()) {
                                    SettingsLink(label: "Calendar", icon: "calendar")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: ActivityLogsView()) {
                                    SettingsLink(label: "Activity Logs", icon: "clock.arrow.circlepath")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: SuggestionsView()) {
                                    SettingsLink(label: "Suggestions", icon: "lightbulb.fill")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: WeeklyPlanView()) {
                                    SettingsLink(label: "Weekly Plan", icon: "calendar.badge.checkmark")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: MonthlyPlanView()) {
                                    SettingsLink(label: "Monthly Plan", icon: "calendar")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: ResourceUsageView()) {
                                    SettingsLink(label: "Resource Usage", icon: "leaf.fill")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: CostOfRoutineView()) {
                                    SettingsLink(label: "Cost of Routines", icon: "eurosign.circle.fill")
                                }
                                Divider().background(Color.cfTextTertiary)
                                NavigationLink(destination: ProfileView()) {
                                    SettingsLink(label: "Profile", icon: "person.fill")
                                }
                            }
                        }

                        // Data
                        SettingsSection(title: "Data", icon: "externaldrive.fill") {
                            VStack(spacing: 0) {
                                NavigationLink(destination: BackupView()) {
                                    SettingsLink(label: "Backup & Data", icon: "externaldrive.fill")
                                }
                                Divider().background(Color.cfTextTertiary)
                                Button(action: { showResetAlert = true }) {
                                    SettingsLink(label: "Reset All Data", icon: "trash.fill", color: .cfAlert)
                                }
                            }
                        }

                        // App info
                        VStack(spacing: 4) {
                            Text("Coop Flow v1.0")
                                .font(.cfCaption())
                                .foregroundColor(.cfTextTertiary)
                            Text("Smart Poultry Care")
                                .font(.cfCaption(10))
                                .foregroundColor(.cfTextTertiary)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    routineStore.routines.removeAll()
                    taskStore.tasks.removeAll()
                    photoStore.photos.removeAll()
                    noteStore.notes.removeAll()
                    appState.resetSetup()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all routines, tasks, photos and notes. This cannot be undone.")
            }
        }
        .sheet(isPresented: $showBirdSetup) {
            SetupView()
        }
    }

    private func backup() {
        // Encode all data and save to UserDefaults as a combined backup
        let backup: [String: Any] = [
            "routines": (try? JSONEncoder().encode(routineStore.routines)) ?? Data(),
            "tasks": (try? JSONEncoder().encode(taskStore.tasks)) ?? Data(),
            "notes": (try? JSONEncoder().encode(noteStore.notes)) ?? Data(),
            "backupDate": Date().timeIntervalSince1970
        ]
        UserDefaults.standard.set(backup, forKey: "coopflow_backup")
        withAnimation { backupDone = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { backupDone = false }
        }
    }
}

// MARK: - Settings helpers
struct SettingsSection<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.cfCaption())
                .foregroundColor(.cfTextSecondary)
                .padding(.horizontal, 18)

            CFCard(padding: 0) {
                content
            }
            .padding(.horizontal, 18)
        }
    }
}

struct SettingsRow<Content: View>: View {
    var label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack {
            Text(label).font(.cfBody()).foregroundColor(.cfText)
            Spacer()
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsLink: View {
    var label: String
    var icon: String
    var color: Color = .cfText

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.cfBody())
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.cfTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Notifications Settings
struct NotificationsSettingsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 16) {
                    CFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notification Status", systemImage: "bell.badge.fill")
                                .font(.cfHeadline()).foregroundColor(.cfText)

                            HStack(spacing: 10) {
                                Circle()
                                    .fill(notificationManager.isAuthorized ? Color.cfSuccess : Color.cfAlert)
                                    .frame(width: 10, height: 10)
                                Text(notificationManager.isAuthorized ? "Notifications are enabled" : "Notifications are disabled")
                                    .font(.cfBody()).foregroundColor(.cfText)
                            }

                            if !notificationManager.isAuthorized {
                                Button(action: {
                                    notificationManager.requestPermission { _ in }
                                }) {
                                    Text("Request Permission")
                                }
                                .buttonStyle(CFPrimaryButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    CFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scheduled Reminders").font(.cfHeadline()).foregroundColor(.cfText)
                            let pending = taskStore.pendingToday()
                            if pending.isEmpty {
                                Text("No pending tasks today").font(.cfBody()).foregroundColor(.cfTextSecondary)
                            } else {
                                ForEach(pending) { task in
                                    HStack {
                                        Text(task.routineIcon).font(.system(size: 20))
                                        Text(task.routineName).font(.cfBody()).foregroundColor(.cfText)
                                        Spacer()
                                        Text(task.scheduledTime).font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.cfAccent)
                                    }
                                    Divider().background(Color.cfTextTertiary)
                                }
                            }

                            Button(action: {
                                notificationManager.scheduleAll(
                                    tasks: taskStore.pendingToday(),
                                    minutesBefore: appState.reminderMinutesBefore
                                )
                            }) {
                                Label("Reschedule All Reminders", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(CFSecondaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 18)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Activity Logs
struct ActivityLogsView: View {
    @EnvironmentObject var taskStore: TaskStore

    private var completedTasks: [DailyTask] {
        taskStore.tasks.filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 12) {
                    CFScreenHeader(title: "Activity Logs", subtitle: "\(completedTasks.count) completed")
                        .padding(.top, 8)

                    ForEach(completedTasks) { task in
                        CFCard(padding: 14) {
                            HStack(spacing: 12) {
                                Text(task.routineIcon).font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.routineName).font(.cfHeadline()).foregroundColor(.cfText)
                                    HStack(spacing: 8) {
                                        if let completed = task.completedAt {
                                            Text(completed, style: .relative)
                                                .font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        }
                                        if let mins = task.actualMinutes {
                                            Label("\(mins) min", systemImage: "clock")
                                                .font(.cfCaption()).foregroundColor(.cfAccent)
                                        }
                                    }
                                    if !task.notes.isEmpty {
                                        Text(task.notes)
                                            .font(.cfCaption())
                                            .foregroundColor(.cfTextSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cfSuccess)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    if completedTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath").font(.system(size: 44)).foregroundColor(.cfTextTertiary)
                            Text("No activity yet").font(.cfHeadline()).foregroundColor(.cfText)
                            Text("Complete tasks to see them here").font(.cfBody()).foregroundColor(.cfTextSecondary)
                        }
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
