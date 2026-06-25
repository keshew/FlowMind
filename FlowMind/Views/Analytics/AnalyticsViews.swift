import SwiftUI

// MARK: - Analytics Hub
struct AnalyticsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()

                VStack(spacing: 0) {
                    CFScreenHeader(title: "Analytics", subtitle: "Track your progress")
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Sub-tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Productivity", "Time", "Efficiency", "Costs", "Trends"].indices, id: \.self) { i in
                                let labels = ["Productivity", "Time", "Efficiency", "Costs", "Trends"]
                                Button(action: { withAnimation { selectedTab = i } }) {
                                    Text(labels[i])
                                        .font(.cfCaption())
                                        .foregroundColor(selectedTab == i ? .white : .cfTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(selectedTab == i ? Color.cfPrimary : Color.cfCard))
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        switch selectedTab {
                        case 0: ProductivityView()
                        case 1: TimeTrackingView()
                        case 2: EfficiencyView()
                        case 3: CostView()
                        case 4: TrendsView()
                        default: ProductivityView()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Productivity
struct ProductivityView: View {
    @EnvironmentObject var taskStore: TaskStore

    var weekStats: [DayStats] { taskStore.last7DaysStats() }
    var overallRate: Double { taskStore.completionRate(last: 7) }

    var body: some View {
        VStack(spacing: 16) {
            // Overall rate
            CFCard {
                VStack(spacing: 12) {
                    Text("7-Day Completion Rate")
                        .font(.cfHeadline())
                        .foregroundColor(.cfText)

                    ZStack {
                        Circle()
                            .stroke(Color.cfCardLight, lineWidth: 12)
                            .frame(width: 120, height: 120)
                        Circle()
                            .trim(from: 0, to: overallRate)
                            .stroke(
                                LinearGradient.cfSuccessGradient,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: overallRate)

                        Text("\(Int(overallRate * 100))%")
                            .font(.cfDisplay(28))
                            .foregroundColor(.cfText)
                    }
                }
            }
            .padding(.horizontal, 18)

            // Bar chart
            CFCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Daily Completion")
                        .font(.cfHeadline())
                        .foregroundColor(.cfText)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(weekStats) { stat in
                            VStack(spacing: 6) {
                                let rate = stat.totalTasks > 0 ? Double(stat.completedTasks) / Double(stat.totalTasks) : 0
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient.cfSuccessGradient)
                                    .frame(width: 32, height: max(4, 100 * rate))
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: rate)
                                Text(dayLabel(stat.date))
                                    .font(.cfCaption(10))
                                    .foregroundColor(.cfTextSecondary)
                            }
                        }
                    }
                    .frame(height: 130)
                }
            }
            .padding(.horizontal, 18)

            // Summary stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                let total7 = weekStats.reduce(0) { $0 + $1.totalTasks }
                let done7 = weekStats.reduce(0) { $0 + $1.completedTasks }
                let missed7 = weekStats.reduce(0) { $0 + $1.missedTasks }

                StatCard(title: "Total Tasks", value: "\(total7)", icon: "list.bullet", color: .cfPrimary)
                StatCard(title: "Completed", value: "\(done7)", icon: "checkmark.circle.fill", color: .cfSuccess)
                StatCard(title: "Missed", value: "\(missed7)", icon: "exclamationmark.circle", color: .cfAlert)
                StatCard(title: "Streak", value: streakDays(), icon: "flame.fill", color: .cfSecondary)
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 100)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func streakDays() -> String {
        var streak = 0
        for offset in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            let stats = taskStore.statsForDate(date)
            if stats.totalTasks == 0 { continue }
            if stats.completedTasks == stats.totalTasks { streak += 1 }
            else { break }
        }
        return "\(streak)d"
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        CFCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(value)
                    .font(.cfDisplay(28))
                    .foregroundColor(.cfText)
                Text(title)
                    .font(.cfCaption())
                    .foregroundColor(.cfTextSecondary)
            }
        }
    }
}

// MARK: - Time Tracking
struct TimeTrackingView: View {
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        VStack(spacing: 16) {
            CFCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Time Spent (Last 7 Days)")
                        .font(.cfHeadline()).foregroundColor(.cfText)

                    let stats = taskStore.last7DaysStats()
                    let maxMin = stats.map { $0.totalMinutes }.max() ?? 1

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(stats) { s in
                            VStack(spacing: 4) {
                                if s.totalMinutes > 0 {
                                    Text("\(s.totalMinutes)m")
                                        .font(.cfCaption(9))
                                        .foregroundColor(.cfPrimaryLight)
                                }
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(LinearGradient.cfPrimaryGradient)
                                    .frame(width: 32, height: max(4, CGFloat(s.totalMinutes) / CGFloat(maxMin) * 90))
                                Text(dayLabel(s.date))
                                    .font(.cfCaption(10))
                                    .foregroundColor(.cfTextSecondary)
                            }
                        }
                    }
                    .frame(height: 130)
                }
            }
            .padding(.horizontal, 18)

            // Average times
            CFCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Average Duration").font(.cfHeadline()).foregroundColor(.cfText)
                    let avg = avgMinutes()
                    HStack {
                        Text("\(avg)")
                            .font(.cfDisplay(40))
                            .foregroundColor(.cfPrimary)
                        Text("min/day")
                            .font(.cfBody())
                            .foregroundColor(.cfTextSecondary)
                            .padding(.bottom, 6)
                    }
                    CFProgressBar(value: Double(avg) / 60.0, color: .cfPrimary)
                    Text("Out of 60 min target")
                        .font(.cfCaption())
                        .foregroundColor(.cfTextSecondary)
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 100)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func avgMinutes() -> Int {
        let stats = taskStore.last7DaysStats()
        let total = stats.reduce(0) { $0 + $1.totalMinutes }
        return stats.isEmpty ? 0 : total / stats.count
    }
}

// MARK: - Efficiency
struct EfficiencyView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore

    var body: some View {
        VStack(spacing: 16) {
            CFCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Time by Category")
                        .font(.cfHeadline()).foregroundColor(.cfText)

                    ForEach(RoutineCategory.allCases, id: \.self) { cat in
                        let routines = routineStore.routines.filter { $0.category == cat }
                        if !routines.isEmpty {
                            let total = routines.reduce(0) { $0 + $1.estimatedMinutes }
                            HStack {
                                Image(systemName: cat.icon)
                                    .foregroundColor(cat.swiftUIColor)
                                    .frame(width: 24)
                                Text(cat.rawValue)
                                    .font(.cfBody())
                                    .foregroundColor(.cfText)
                                Spacer()
                                Text("\(total) min")
                                    .font(.cfCaption())
                                    .foregroundColor(.cfTextSecondary)
                            }
                            CFProgressBar(value: Double(total) / 60.0, color: cat.swiftUIColor, height: 6)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)

            // Suggestions preview
            NavigationLink(destination: ResourceUsageView()) {
                HStack {
                    Image(systemName: "leaf.fill").foregroundColor(Color(hex: "#4CAF50"))
                    Text("Resource Usage").font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.white.opacity(0.3))
                }
                .padding(14)
                .background(Color(hex: "#2F3147"))
                .cornerRadius(12)
            }
            NavigationLink(destination: CostOfRoutineView()) {
                HStack {
                    Image(systemName: "eurosign.circle.fill").foregroundColor(Color(hex: "#FF9F5A"))
                    Text("Cost of Routines").font(.system(.subheadline, design: .rounded)).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.white.opacity(0.3))
                }
                .padding(14)
                .background(Color(hex: "#2F3147"))
                .cornerRadius(12)
            }
            NavigationLink(destination: SuggestionsView()) {
                CFCard(padding: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.cfAccent)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Optimization Suggestions")
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)
                            Text("Tap to see AI-powered tips")
                                .font(.cfCaption())
                                .foregroundColor(.cfTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.cfTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 100)
        }
    }
}

// MARK: - Cost View
struct CostView: View {
    @EnvironmentObject var routineStore: RoutineStore

    var body: some View {
        VStack(spacing: 16) {
            // Monthly cost estimate
            let dailyCost = routineStore.routines.filter { $0.isActive }
                .reduce(0.0) { $0 + $1.costPerSession * Double($1.schedule.times.count) }
            let monthlyCost = dailyCost * 30
            let yearlyCost = dailyCost * 365

            CFCard {
                VStack(spacing: 16) {
                    Text("Cost Overview")
                        .font(.cfHeadline()).foregroundColor(.cfText)

                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text(String(format: "€%.2f", dailyCost))
                                .font(.cfDisplay(22)).foregroundColor(.cfAccent)
                            Text("Per Day").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                        }
                        Divider().background(Color.cfTextTertiary).frame(height: 40)
                        VStack(spacing: 4) {
                            Text(String(format: "€%.2f", monthlyCost))
                                .font(.cfDisplay(22)).foregroundColor(.cfSecondary)
                            Text("Per Month").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                        }
                        Divider().background(Color.cfTextTertiary).frame(height: 40)
                        VStack(spacing: 4) {
                            Text(String(format: "€%.0f", yearlyCost))
                                .font(.cfDisplay(22)).foregroundColor(.cfAlert)
                            Text("Per Year").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)

            // Per routine breakdown
            CFCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cost by Routine")
                        .font(.cfHeadline()).foregroundColor(.cfText)

                    ForEach(routineStore.routines.filter { $0.isActive }) { r in
                        HStack {
                            Text(r.icon).font(.system(size: 22))
                            Text(r.name).font(.cfBody()).foregroundColor(.cfText)
                            Spacer()
                            Text(String(format: "€%.2f/session", r.costPerSession))
                                .font(.cfCaption())
                                .foregroundColor(.cfTextSecondary)
                        }
                        if r.id != routineStore.routines.last?.id {
                            Divider().background(Color.cfTextTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)

            // Resource usage
            CFCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resource Usage (Daily)")
                        .font(.cfHeadline()).foregroundColor(.cfText)

                    let totalFeed = routineStore.routines.filter { $0.isActive }.reduce(0.0) { $0 + $1.feedAmount }
                    let totalWater = routineStore.routines.filter { $0.isActive }.reduce(0.0) { $0 + $1.waterAmount }

                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Image(systemName: "leaf.fill").foregroundColor(.cfSuccess).font(.system(size: 24))
                            Text("\(Int(totalFeed))g").font(.cfDisplay(22)).foregroundColor(.cfText)
                            Text("Feed").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                        }
                        Divider().background(Color.cfTextTertiary).frame(height: 50)
                        VStack(spacing: 4) {
                            Image(systemName: "drop.fill").foregroundColor(.cfPrimaryLight).font(.system(size: 24))
                            Text(String(format: "%.1fL", totalWater)).font(.cfDisplay(22)).foregroundColor(.cfText)
                            Text("Water").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 100)
        }
    }
}

// MARK: - Trends
struct TrendsView: View {
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        VStack(spacing: 16) {
            CFCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("30-Day Activity")
                        .font(.cfHeadline()).foregroundColor(.cfText)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                        ForEach(0..<28, id: \.self) { i in
                            let date = Calendar.current.date(byAdding: .day, value: -(27 - i), to: Date())!
                            let stats = taskStore.statsForDate(date)
                            let rate: Double = stats.totalTasks > 0 ? Double(stats.completedTasks) / Double(stats.totalTasks) : 0

                            RoundedRectangle(cornerRadius: 4)
                                .fill(rateColor(rate, total: stats.totalTasks))
                                .frame(height: 28)
                                .overlay(
                                    Text(dayInitial(date))
                                        .font(.cfCaption(8))
                                        .foregroundColor(.cfText.opacity(0.5))
                                )
                        }
                    }

                    HStack(spacing: 8) {
                        Text("Less").font(.cfCaption(10)).foregroundColor(.cfTextSecondary)
                        ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(rateColor(v, total: 3))
                                .frame(width: 14, height: 14)
                        }
                        Text("More").font(.cfCaption(10)).foregroundColor(.cfTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 100)
        }
    }

    private func rateColor(_ rate: Double, total: Int) -> Color {
        if total == 0 { return Color.cfCardLight }
        if rate >= 1.0 { return Color.cfSuccess }
        if rate >= 0.7 { return Color.cfSuccess.opacity(0.6) }
        if rate >= 0.4 { return Color.cfAccent.opacity(0.6) }
        return Color.cfAlert.opacity(0.4)
    }

    private func dayInitial(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }
}
