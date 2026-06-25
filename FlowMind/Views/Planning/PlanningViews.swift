import SwiftUI

// MARK: - Weekly Plan View
struct WeeklyPlanView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore
    @State private var selectedWeekOffset: Int = 0

    private var weekDates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysFromMonday + selectedWeekOffset * 7, to: today)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private var weekLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        guard let first = weekDates.first, let last = weekDates.last else { return "" }
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Week navigator
                    HStack {
                        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedWeekOffset -= 1 } } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#4A90E2"))
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text(selectedWeekOffset == 0 ? "This Week" : selectedWeekOffset == -1 ? "Last Week" : selectedWeekOffset == 1 ? "Next Week" : "")
                                .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#4A90E2"))
                            Text(weekLabel)
                                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedWeekOffset += 1 } } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#4A90E2"))
                        }
                    }
                    .padding(.horizontal, 16)

                    // Day columns
                    weeklyGrid

                    // Active routines this week
                    weekRoutineSummary
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Weekly Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var weeklyGrid: some View {
        let cal = Calendar.current
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    let date = weekDates[i]
                    let isToday = cal.isDateInToday(date)
                    let tasks = taskStore.tasks(for: date)
                    let done = tasks.filter { $0.status == .completed }.count
                    let total = tasks.count

                    VStack(spacing: 6) {
                        Text(dayNames[i])
                            .font(.system(.caption2, design: .rounded)).fontWeight(.semibold)
                            .foregroundColor(isToday ? Color(hex: "#4A90E2") : Color.white.opacity(0.5))

                        Text("\(cal.component(.day, from: date))")
                            .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(isToday ? .white : Color.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(isToday ? Color(hex: "#4A90E2") : Color(hex: "#2F3147"))
                            .clipShape(Circle())

                        if total > 0 {
                            VStack(spacing: 3) {
                                ForEach(0..<min(total, 3), id: \.self) { idx in
                                    let t = tasks[idx]
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(t.status == .completed ? Color(hex: "#4CAF50") : t.status == .missed ? Color(hex: "#FF6B6B") : Color(hex: "#FFC933"))
                                        .frame(height: 6)
                                }
                                if total > 3 {
                                    Text("+\(total-3)")
                                        .font(.system(size: 9, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.4))
                                }
                            }
                            Text("\(done)/\(total)")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(done == total ? Color(hex: "#4CAF50") : Color.white.opacity(0.5))
                        } else {
                            Text("—")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.2))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#2F3147").opacity(isToday ? 1 : 0.6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)

            // Week summary bar
            let allTasks = weekDates.flatMap { taskStore.tasks(for: $0) }
            let totalDone = allTasks.filter { $0.status == .completed }.count
            let totalTasks = allTasks.count
            if totalTasks > 0 {
                CFCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week Progress")
                                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("\(totalDone) of \(totalTasks) tasks done")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color(hex: "#2F3147"), lineWidth: 5)
                                .frame(width: 48, height: 48)
                            Circle()
                                .trim(from: 0, to: totalTasks > 0 ? CGFloat(totalDone) / CGFloat(totalTasks) : 0)
                                .stroke(Color(hex: "#4CAF50"), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(totalTasks > 0 ? CGFloat(totalDone) / CGFloat(totalTasks) * 100 : 0))%")
                                .font(.system(size: 11, design: .rounded)).fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var weekRoutineSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Routines")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            let active = routineStore.routines.filter { $0.isActive }
            if active.isEmpty {
                CFCard {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("No active routines")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
            } else {
                ForEach(active) { routine in
                    CFCard {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: routine.color).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: routine.icon)
                                    .font(.system(.subheadline))
                                    .foregroundColor(Color(hex: routine.color))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name)
                                    .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Text(routine.category.rawValue)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(routine.estimatedMinutes) min")
                                    .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "#FFC933"))
                                Text("× 7 days")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Monthly Plan View
struct MonthlyPlanView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore
    @State private var selectedMonthOffset: Int = 0
    @State private var selectedDate: Date? = nil

    private var displayMonth: Date {
        Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
    }

    private var monthLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayMonth)
    }

    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: displayMonth)
        comps.day = 1
        guard let firstDay = cal.date(from: comps) else { return [] }
        let weekday = (cal.component(.weekday, from: firstDay) + 5) % 7 // 0=Mon
        let range = cal.range(of: .day, in: .month, for: firstDay)!
        var result: [Date?] = Array(repeating: nil, count: weekday)
        for d in range {
            comps.day = d
            result.append(cal.date(from: comps))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Month navigator
                    HStack {
                        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedMonthOffset -= 1 } } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2).foregroundColor(Color(hex: "#4A90E2"))
                        }
                        Spacer()
                        Text(monthLabel)
                            .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedMonthOffset += 1 } } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2).foregroundColor(Color(hex: "#4A90E2"))
                        }
                    }
                    .padding(.horizontal, 16)

                    monthCalendarGrid

                    if let date = selectedDate {
                        dayDetailSection(date: date)
                    }

                    monthStats
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Monthly Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthCalendarGrid: some View {
        CFCard {
            VStack(spacing: 8) {
                // Weekday headers
                HStack {
                    ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                        Text(d)
                            .font(.system(.caption, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(Color.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }

                let weeks = daysInMonth.chunked(into: 7)
                ForEach(0..<weeks.count, id: \.self) { wi in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { di in
                            let date = weeks[wi][di]
                            dayCell(date: date)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func dayCell(date: Date?) -> some View {
        let cal = Calendar.current
        if let date = date {
            let isToday = cal.isDateInToday(date)
            let isSelected = selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false
            let tasks = taskStore.tasks(for: date)
            let done = tasks.filter { $0.status == .completed }.count
            let missed = tasks.filter { $0.status == .missed }.count
            let pending = tasks.filter { $0.status == .pending }.count

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedDate = isSelected ? nil : date
                }
            } label: {
                VStack(spacing: 2) {
                    Text("\(cal.component(.day, from: date))")
                        .font(.system(.caption, design: .rounded)).fontWeight(isToday ? .bold : .medium)
                        .foregroundColor(isToday ? .black : isSelected ? Color(hex: "#4A90E2") : .white)
                        .frame(width: 28, height: 28)
                        .background(isToday ? Color.white : isSelected ? Color(hex: "#4A90E2").opacity(0.2) : Color.clear)
                        .clipShape(Circle())

                    HStack(spacing: 2) {
                        if done > 0 { Circle().fill(Color(hex: "#4CAF50")).frame(width: 4, height: 4) }
                        if missed > 0 { Circle().fill(Color(hex: "#FF6B6B")).frame(width: 4, height: 4) }
                        if pending > 0 { Circle().fill(Color(hex: "#FFC933")).frame(width: 4, height: 4) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: 40)
        }
    }

    @ViewBuilder
    private func dayDetailSection(date: Date) -> some View {
        let tasks = taskStore.tasks(for: date)
        VStack(alignment: .leading, spacing: 10) {
            let fmt = DateFormatter()
            let _ = { fmt.dateFormat = "EEEE, MMM d" }()
            Text(fmt.string(from: date))
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            if tasks.isEmpty {
                CFCard {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("No tasks for this day")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
            } else {
                ForEach(tasks) { task in
                    CFCard {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(task.status == .completed ? Color(hex: "#4CAF50") :
                                      task.status == .missed ? Color(hex: "#FF6B6B") : Color(hex: "#FFC933"))
                                .frame(width: 10, height: 10)
                            Text(task.routineName)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(task.status.rawValue.capitalized)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var monthStats: some View {
        let allDates = daysInMonth.compactMap { $0 }
        let allTasks = allDates.flatMap { taskStore.tasks(for: $0) }
        let done = allTasks.filter { $0.status == .completed }.count
        let missed = allTasks.filter { $0.status == .missed }.count
        let total = allTasks.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("Month Summary")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            CFCard {
                HStack(spacing: 0) {
                    statPill(value: total, label: "Total", color: "#4A90E2")
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    statPill(value: done, label: "Done", color: "#4CAF50")
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    statPill(value: missed, label: "Missed", color: "#FF6B6B")
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    statPill(value: total > 0 ? Int(Double(done)/Double(total)*100) : 0, label: "Rate %", color: "#FFC933")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func statPill(value: Int, label: String, color: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title3, design: .rounded)).fontWeight(.bold)
                .foregroundColor(Color(hex: color))
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Resource Usage View
struct ResourceUsageView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var period: Int = 0 // 0=week, 1=month, 2=year

    private var multiplier: Double {
        switch period {
        case 0: return 7
        case 1: return 30
        default: return 365
        }
    }

    private var periodLabel: String {
        ["Per Week", "Per Month", "Per Year"][period]
    }

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    Picker("Period", selection: $period) {
                        Text("Week").tag(0)
                        Text("Month").tag(1)
                        Text("Year").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    totalResourceCards

                    perRoutineBreakdown

                    tipsSection
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Resource Usage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalFeedKg: Double {
        routineStore.routines.filter { $0.isActive }.reduce(into: 0) { $0 + $1.feedAmount } * multiplier
    }

    private var totalWaterL: Double {
        routineStore.routines.filter { $0.isActive }.reduce(into: 0) { $0 + $1.waterAmount } * multiplier
    }

    private var totalTimeH: Double {
        0 // routineStore.routines.filter { $0.isActive }.reduce(into: 0) { $0 + Double($1.createdAt) } * multiplier / 60.0
    }

    private var totalCost: Double {
        routineStore.routines.filter { $0.isActive }.reduce(into: 0) { $0 + $1.costPerSession } * multiplier
    }

    private var totalResourceCards: some View {
        VStack(spacing: 12) {
            Text("Total Usage · \(periodLabel)")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                resourceCard(icon: "leaf.fill", label: "Feed", value: String(format: "%.1f kg", totalFeedKg), color: "#4CAF50")
                resourceCard(icon: "drop.fill", label: "Water", value: String(format: "%.1f L", totalWaterL), color: "#4A90E2")
                resourceCard(icon: "clock.fill", label: "Time", value: String(format: "%.1f h", totalTimeH), color: "#FFC933")
                resourceCard(icon: "eurosign.circle.fill", label: "Cost", value: String(format: "€%.2f", totalCost), color: "#FF9F5A")
            }
            .padding(.horizontal, 16)
        }
    }

    private func resourceCard(icon: String, label: String, value: String, color: String) -> some View {
        CFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(Color(hex: color))
                    Spacer()
                }
                Text(value)
                    .font(.system(.title2, design: .rounded)).fontWeight(.bold)
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
    }

    private var perRoutineBreakdown: some View {
        let active = routineStore.routines.filter { $0.isActive }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Per Routine")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            if active.isEmpty {
                CFCard {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(Color.white.opacity(0.3))
                        Text("No active routines")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 16)
            } else {
                ForEach(active) { routine in
                    CFCard {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: routine.color).opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: routine.icon)
                                        .font(.system(.caption))
                                        .foregroundColor(Color(hex: routine.color))
                                }
                                Text(routine.name)
                                    .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(String(format: "€%.2f", routine.costPerSession * multiplier))
                                    .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#FF9F5A"))
                            }

                            Divider().background(Color.white.opacity(0.08))

                            HStack {
                                miniStat(icon: "leaf", value: String(format: "%.1f kg", routine.feedAmount / 1000.0 * multiplier), color: "#4CAF50")
                                Spacer()
                                miniStat(icon: "drop", value: String(format: "%.1f L", routine.waterAmount * multiplier), color: "#4A90E2")
                                Spacer()
                                miniStat(icon: "clock", value: "\(Int(Double(routine.estimatedMinutes) * multiplier / 60))h \(Int(Double(routine.estimatedMinutes) * multiplier) % 60)m", color: "#FFC933")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func miniStat(icon: String, value: String, color: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(Color(hex: color))
            Text(value)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saving Tips")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            let tips = [
                ("💧", "Batch water refills to reduce trips by up to 40%"),
                ("🌾", "Buy feed in bulk — save up to 20% on costs"),
                ("⏱️", "Combine morning routines to save 15 min/day"),
                ("📊", "Track actual vs estimated to improve planning")
            ]
            ForEach(tips, id: \.0) { tip in
                CFCard {
                    HStack(spacing: 12) {
                        Text(tip.0).font(.title3)
                        Text(tip.1)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Cost of Routine Detail View
struct CostOfRoutineView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @State private var period: Int = 1

    private var multiplier: Double {
        switch period {
        case 0: return 7
        case 1: return 30
        default: return 365
        }
    }

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Period", selection: $period) {
                        Text("Week").tag(0)
                        Text("Month").tag(1)
                        Text("Year").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    let active = routineStore.routines.filter { $0.isActive }
                    let total = active.reduce(0.0) { $0 + $1.costPerSession } * multiplier

                    // Total cost ring
                    CFCard {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "#2F3147"), lineWidth: 12)
                                    .frame(width: 120, height: 120)
                                Circle()
                                    .trim(from: 0, to: 1)
                                    .stroke(
                                        LinearGradient(colors: [Color(hex: "#FF9F5A"), Color(hex: "#FFC933")],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                VStack(spacing: 2) {
                                    Text(String(format: "€%.2f", total))
                                        .font(.system(.title2, design: .rounded)).fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text(["/ week", "/ month", "/ year"][period])
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                            }
                            Text("Total Care Cost")
                                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 16)

                    // Per routine breakdown with cost bars
                    if !active.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Breakdown")
                                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)

                            ForEach(active.sorted(by: { $0.costPerSession > $1.costPerSession })) { routine in
                                let cost = routine.costPerSession * multiplier
                                let fraction = total > 0 ? cost / total : 0
                                CFCard {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: routine.icon)
                                                .foregroundColor(Color(hex: routine.color))
                                            Text(routine.name)
                                                .font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text(String(format: "€%.2f", cost))
                                                .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                                                .foregroundColor(Color(hex: "#FF9F5A"))
                                        }
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color(hex: "#3A3D5C"))
                                                    .frame(height: 8)
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(LinearGradient(colors: [Color(hex: "#FF9F5A"), Color(hex: "#FFC933")],
                                                                         startPoint: .leading, endPoint: .trailing))
                                                    .frame(width: geo.size.width * CGFloat(fraction), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                        HStack {
                                            Text(String(format: "%.0f%% of total", fraction * 100))
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundColor(Color.white.opacity(0.4))
                                            Spacer()
                                            Text("€\(String(format: "%.3f", routine.costPerSession))/session")
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundColor(Color.white.opacity(0.4))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Cost of Care")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var editingName = false
    @State private var draftName = ""
    @State private var showBirdSetup = false

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar + name
                    avatarSection

                    // Flock info
                    flockCard

                    // Stats overview
                    statsOverview

                    // Achievements
                    achievementsSection
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBirdSetup) {
            SetupView()
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "#4A90E2"), Color(hex: "#5BA3F5")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                Text(String(appState.userName.prefix(1)).uppercased().isEmpty ? "🐔" : String(appState.userName.prefix(1)).uppercased())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: Color(hex: "#4A90E2").opacity(0.4), radius: 12, y: 4)

            if editingName {
                HStack {
                    TextField("Your name", text: $draftName)
                        .font(.system(.title3, design: .rounded)).fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                    Button {
                        if !draftName.trimmingCharacters(in: .whitespaces).isEmpty {
                            appState.userName = draftName.trimmingCharacters(in: .whitespaces)
                        }
                        editingName = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#4CAF50"))
                    }
                }
                .padding(.horizontal, 40)
            } else {
                HStack(spacing: 6) {
                    Text(appState.userName.isEmpty ? "Poultry Keeper" : appState.userName)
                        .font(.system(.title3, design: .rounded)).fontWeight(.bold)
                        .foregroundColor(.white)
                    Button {
                        draftName = appState.userName
                        editingName = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#4A90E2"))
                    }
                }
            }

            Text("Coop Flow Member")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
        }
    }

    private var flockCard: some View {
        CFCard {
            VStack(spacing: 12) {
                HStack {
                    Text("My Flock")
                        .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        showBirdSetup = true
                    } label: {
                        Text("Edit")
                            .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#4A90E2"))
                    }
                }

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(appState.birdCount)")
                            .font(.system(.largeTitle, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(Color(hex: "#FFC933"))
                        Text("Birds")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    VStack(spacing: 4) {
                        Text(appState.birdType.rawValue)
                            .font(.system(.title3, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(Color(hex: "#FF9F5A"))
                        Text("Type")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    VStack(spacing: 4) {
                        Text("\(routineStore.routines.filter { $0.isActive }.count)")
                            .font(.system(.title3, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(Color(hex: "#4CAF50"))
                        Text("Routines")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    private var statsOverview: some View {
        let allTasks = taskStore.allTasksForStats()
        let completed = allTasks.filter { $0.status == .completed }.count
        let total = allTasks.count
        let streak = taskStore.currentStreak()

        return VStack(alignment: .leading, spacing: 12) {
            Text("All-Time Stats")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(icon: "checkmark.circle.fill", label: "Completed", value: "\(completed)", color: "#4CAF50")
                statCard(icon: "flame.fill", label: "Day Streak", value: "\(streak)", color: "#FF9F5A")
                statCard(icon: "list.bullet.clipboard", label: "Total Tasks", value: "\(total)", color: "#4A90E2")
                statCard(icon: "percent", label: "Success Rate", value: total > 0 ? "\(Int(Double(completed)/Double(total)*100))%" : "—", color: "#FFC933")
            }
            .padding(.horizontal, 16)
        }
    }

    private func statCard(icon: String, label: String, value: String, color: String) -> some View {
        CFCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: color))
                Text(value)
                    .font(.system(.title2, design: .rounded)).fontWeight(.bold)
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
    }

    private var achievementsSection: some View {
        let allTasks = taskStore.allTasksForStats()
        let completed = allTasks.filter { $0.status == .completed }.count
        let streak = taskStore.currentStreak()

        let badges: [(String, String, String, Bool)] = [
            ("🐣", "First Steps", "Complete your first task", completed >= 1),
            ("🌟", "On a Roll", "Complete 10 tasks", completed >= 10),
            ("🔥", "Hot Streak", "7-day streak", streak >= 7),
            ("🏆", "Centurion", "Complete 100 tasks", completed >= 100),
            ("🌱", "Eco Keeper", "Log resources for 7 days", streak >= 7),
            ("📸", "Photo Pro", "Add 5 photos", false)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(badges, id: \.1) { badge in
                    VStack(spacing: 6) {
                        Text(badge.0)
                            .font(.system(size: 32))
                            .opacity(badge.3 ? 1 : 0.25)
                        Text(badge.1)
                            .font(.system(.caption2, design: .rounded)).fontWeight(.semibold)
                            .foregroundColor(badge.3 ? .white : Color.white.opacity(0.3))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#2F3147").opacity(badge.3 ? 1 : 0.5))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(badge.3 ? Color(hex: "#FFC933").opacity(0.4) : Color.clear, lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Backup View
struct BackupView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var photoStore: PhotoStore
    @EnvironmentObject var noteStore: NoteStore
    @State private var showExportSuccess = false
    @State private var showImportAlert = false
    @State private var showResetConfirm = false
    @State private var lastBackupDate: Date? = {
        if let ts = UserDefaults.standard.object(forKey: "lastBackupTimestamp") as? Double {
            return Date(timeIntervalSince1970: ts)
        }
        return nil
    }()

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 20) {
                    backupStatusCard
                    backupActions
                    dataOverview
                    dangerZone
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Backup & Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Backup Saved", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been backed up to UserDefaults successfully.")
        }
        .alert("Reset All Data", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { performReset() }
        } message: {
            Text("This will permanently delete all routines, tasks, photos, and notes. This cannot be undone.")
        }
    }

    private var backupStatusCard: some View {
        CFCard {
            VStack(spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: lastBackupDate != nil ? "#4CAF50" : "#FF6B6B").opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: lastBackupDate != nil ? "checkmark.icloud.fill" : "xmark.icloud")
                            .font(.title2)
                            .foregroundColor(Color(hex: lastBackupDate != nil ? "#4CAF50" : "#FF6B6B"))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lastBackupDate != nil ? "Data Backed Up" : "No Backup Yet")
                            .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                            .foregroundColor(.white)
                        if let date = lastBackupDate {
                            let fmt = RelativeDateTimeFormatter()
                            Text("Last backup: \(fmt.localizedString(for: date, relativeTo: Date()))")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                        } else {
                            Text("Tap 'Backup Now' to save your data")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var backupActions: some View {
        VStack(spacing: 12) {
            Button { performBackup() } label: {
                HStack {
                    Image(systemName: "icloud.and.arrow.up.fill")
                    Text("Backup Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [Color(hex: "#4A90E2"), Color(hex: "#5BA3F5")],
                                           startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(14)
                .font(.system(.subheadline, design: .rounded))
            }
            .padding(.horizontal, 16)

            Button { showImportAlert = true } label: {
                HStack {
                    Image(systemName: "icloud.and.arrow.down.fill")
                    Text("Restore from Backup")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#2F3147"))
                .foregroundColor(Color(hex: "#4A90E2"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#4A90E2").opacity(0.4), lineWidth: 1))
                .font(.system(.subheadline, design: .rounded))
            }
            .padding(.horizontal, 16)
            .alert("Restore Data", isPresented: $showImportAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Restore", role: .destructive) { performRestore() }
            } message: {
                Text("This will reload data from your last backup. Current unsaved data will be overwritten.")
            }
        }
    }

    private var dataOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Overview")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            CFCard {
                VStack(spacing: 10) {
                    dataRow(icon: "arrow.triangle.2.circlepath", label: "Routines", value: "\(routineStore.routines.count)", color: "#FF9F5A")
                    Divider().background(Color.white.opacity(0.08))
                    dataRow(icon: "checkmark.circle", label: "Tasks (all)", value: "\(taskStore.allTasksForStats().count)", color: "#4A90E2")
                    Divider().background(Color.white.opacity(0.08))
                    dataRow(icon: "photo", label: "Photos", value: "\(photoStore.photos.count)", color: "#4CAF50")
                    Divider().background(Color.white.opacity(0.08))
                    dataRow(icon: "note.text", label: "Notes", value: "\(noteStore.notes.count)", color: "#FFC933")
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func dataRow(icon: String, label: String, value: String, color: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Color(hex: color))
                .frame(width: 24)
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(.white)
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.system(.headline, design: .rounded)).fontWeight(.bold)
                .foregroundColor(Color(hex: "#FF6B6B"))
                .padding(.horizontal, 16)

            CFCard {
                Button { showResetConfirm = true } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Reset All Data")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(Color(hex: "#FF6B6B"))
                    .font(.system(.subheadline, design: .rounded))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func performBackup() {
        // Save a backup snapshot to UserDefaults
        let ts = Date().timeIntervalSince1970
        UserDefaults.standard.set(ts, forKey: "lastBackupTimestamp")

        // Persist current data (stores already persist, this just marks the timestamp)
        routineStore.save()
        taskStore.save()
        photoStore.save()
        noteStore.save()

        lastBackupDate = Date(timeIntervalSince1970: ts)
        showExportSuccess = true
    }

    private func performRestore() {
        // Reload from UserDefaults (stores reload from stored data)
        routineStore.reload()
        taskStore.reload()
        photoStore.reload()
        noteStore.reload()
    }

    private func performReset() {
        routineStore.resetAll()
        taskStore.resetAll()
        photoStore.resetAll()
        noteStore.resetAll()
        UserDefaults.standard.removeObject(forKey: "lastBackupTimestamp")
        lastBackupDate = nil
    }
}

// MARK: - Array chunked helper
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
