import SwiftUI
import Combine

class TaskStore: ObservableObject {
    @Published var tasks: [DailyTask] = []

    private let key = "coopflow_tasks"

    init() {
        load()
    }

    // MARK: - Task Generation
    func generateTasks(for date: Date, from routines: [Routine]) {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date) - 1 // 0=Sun
        let dateKey = calendar.startOfDay(for: date)

        let existing = tasks.filter { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
        if !existing.isEmpty { return }

        var newTasks: [DailyTask] = []
        for routine in routines where routine.isActive {
            let schedule = routine.schedule
            let shouldRun: Bool
            switch schedule.frequency {
            case .daily:
                shouldRun = true
            case .weekdays:
                shouldRun = dayOfWeek >= 1 && dayOfWeek <= 5
            case .weekends:
                shouldRun = dayOfWeek == 0 || dayOfWeek == 6
            case .custom, .weekly:
                shouldRun = schedule.daysOfWeek.contains(dayOfWeek)
            }

            if shouldRun {
                for time in schedule.times {
                    let task = DailyTask(
                        routineId: routine.id,
                        routineName: routine.name,
                        routineIcon: routine.icon,
                        routineCategory: routine.category,
                        scheduledTime: time,
                        scheduledDate: dateKey,
                        steps: routine.steps.map {
                            TaskStepCompletion(stepId: $0.id, stepTitle: $0.title)
                        }
                    )
                    newTasks.append(task)
                }
            }
        }

        tasks.append(contentsOf: newTasks)
        checkAndMarkMissed()
        save()
    }

    func tasksForDate(_ date: Date) -> [DailyTask] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    func pendingToday() -> [DailyTask] {
        tasksForDate(Date()).filter { $0.status == .pending || $0.status == .inProgress }
    }

    func completedToday() -> [DailyTask] {
        tasksForDate(Date()).filter { $0.status == .completed }
    }

    func missedToday() -> [DailyTask] {
        tasksForDate(Date()).filter { $0.status == .missed }
    }

    // MARK: - Task Actions
    func completeTask(_ id: UUID, minutes: Int? = nil) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].status = .completed
            tasks[idx].completedAt = Date()
            tasks[idx].actualMinutes = minutes
            save()
        }
    }

    func skipTask(_ id: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].status = .skipped
            save()
        }
    }

    func startTask(_ id: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].status = .inProgress
            save()
        }
    }

    func updateTaskNote(_ id: UUID, note: String) {
        if let idx = tasks.firstIndex(where: { $0.id == id }) {
            tasks[idx].notes = note
            save()
        }
    }

    func addPhotoToTask(_ taskId: UUID, photoId: UUID) {
        if let idx = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[idx].photoIds.append(photoId)
            save()
        }
    }

    func completeStep(_ taskId: UUID, stepId: UUID) {
        if let tIdx = tasks.firstIndex(where: { $0.id == taskId }),
           let sIdx = tasks[tIdx].steps.firstIndex(where: { $0.id == stepId }) {
            tasks[tIdx].steps[sIdx].isCompleted.toggle()
            tasks[tIdx].steps[sIdx].completedAt = tasks[tIdx].steps[sIdx].isCompleted ? Date() : nil
            save()
        }
    }

    // MARK: - Analytics
    func statsForDate(_ date: Date) -> DayStats {
        let dayTasks = tasksForDate(date)
        return DayStats(
            date: date,
            totalTasks: dayTasks.count,
            completedTasks: dayTasks.filter { $0.status == .completed }.count,
            missedTasks: dayTasks.filter { $0.status == .missed }.count,
            totalMinutes: dayTasks.compactMap { $0.actualMinutes }.reduce(0, +),
            totalCost: 0,
            totalFeedGrams: 0,
            totalWaterLiters: 0
        )
    }

    func last7DaysStats() -> [DayStats] {
        (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return statsForDate(date)
        }.reversed()
    }

    func completionRate(last days: Int = 7) -> Double {
        let allTasks = (0..<days).flatMap { offset -> [DailyTask] in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return tasksForDate(date)
        }
        guard !allTasks.isEmpty else { return 0 }
        let completed = allTasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(allTasks.count)
    }

    private func checkAndMarkMissed() {
        let now = Date()
        let calendar = Calendar.current
        for idx in tasks.indices {
            guard tasks[idx].status == .pending else { continue }
            let taskDate = tasks[idx].scheduledDate
            let timeStr = tasks[idx].scheduledTime
            let components = timeStr.split(separator: ":").compactMap { Int($0) }
            if components.count == 2 {
                var dc = calendar.dateComponents([.year, .month, .day], from: taskDate)
                dc.hour = components[0]
                dc.minute = components[1]
                if let taskTime = calendar.date(from: dc), taskTime < now,
                   !calendar.isDateInToday(taskDate) || taskTime.timeIntervalSince(now) < -3600 {
                    tasks[idx].status = .missed
                }
            }
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([DailyTask].self, from: data) {
            tasks = decoded
        }
    }

    func reload() {
        load()
    }

    func resetAll() {
        tasks = []
        UserDefaults.standard.removeObject(forKey: key)
    }

    /// All tasks regardless of date, for stats/profile
    func allTasksForStats() -> [DailyTask] {
        return tasks
    }

    /// Tasks for a specific date
    func tasks(for date: Date) -> [DailyTask] {
        let cal = Calendar.current
        return tasks.filter { cal.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    /// Current completion streak (consecutive days with all tasks done or today)
    func currentStreak() -> Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        for _ in 0..<365 {
            let dayTasks = tasks(for: checkDate)
            if dayTasks.isEmpty {
                if cal.isDateInToday(checkDate) {
                    checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
                    continue
                } else {
                    break
                }
            }
            let allDone = dayTasks.allSatisfy { $0.status == .completed || $0.status == .skipped }
            if allDone {
                streak += 1
            } else if !cal.isDateInToday(checkDate) {
                break
            }
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }
}
