import SwiftUI
import Combine

class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []

    private let key = "coopflow_routines"

    init() {
        load()
        if routines.isEmpty { seedDefaults() }
    }

    func add(_ routine: Routine) {
        routines.append(routine)
        save()
    }

    func update(_ routine: Routine) {
        if let idx = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[idx] = routine
            save()
        }
    }

    func delete(_ id: UUID) {
        routines.removeAll { $0.id == id }
        save()
    }

    func toggleActive(_ id: UUID) {
        if let idx = routines.firstIndex(where: { $0.id == id }) {
            routines[idx].isActive.toggle()
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
        }
    }

    private func seedDefaults() {
        let feeding = Routine(
            name: "Morning Feeding",
            icon: "🌅",
            category: .feeding,
            steps: [
                RoutineStep(title: "Prepare feed", description: "Measure correct amount of grain/pellets", estimatedMinutes: 2),
                RoutineStep(title: "Fill feeders", description: "Distribute feed evenly across all feeders", estimatedMinutes: 3),
                RoutineStep(title: "Check for spoilage", description: "Remove any leftover spoiled feed", estimatedMinutes: 2)
            ],
            schedule: RoutineSchedule(frequency: .daily, times: ["08:00"], daysOfWeek: [0,1,2,3,4,5,6]),
            estimatedMinutes: 7,
            costPerSession: 1.5,
            feedAmount: 500,
            waterAmount: 0,
            color: "#FF9F5A"
        )

        let water = Routine(
            name: "Water Check",
            icon: "💧",
            category: .water,
            steps: [
                RoutineStep(title: "Check water level", description: "Ensure drinkers are full", estimatedMinutes: 1),
                RoutineStep(title: "Clean drinkers", description: "Rinse and refill if dirty", estimatedMinutes: 3),
                RoutineStep(title: "Check water quality", description: "Clear, no algae", estimatedMinutes: 1)
            ],
            schedule: RoutineSchedule(frequency: .daily, times: ["08:00", "17:00"], daysOfWeek: [0,1,2,3,4,5,6]),
            estimatedMinutes: 5,
            costPerSession: 0.2,
            feedAmount: 0,
            waterAmount: 5.0,
            color: "#5BA3F5"
        )

        let cleaning = Routine(
            name: "Coop Cleaning",
            icon: "🧹",
            category: .cleaning,
            steps: [
                RoutineStep(title: "Remove droppings", description: "Scrape dropping board and floor", estimatedMinutes: 10),
                RoutineStep(title: "Replace bedding", description: "Add fresh shavings or straw", estimatedMinutes: 8),
                RoutineStep(title: "Ventilation check", description: "Clear vents of debris", estimatedMinutes: 2)
            ],
            schedule: RoutineSchedule(frequency: .weekends, times: ["10:00"], daysOfWeek: [0, 6]),
            estimatedMinutes: 20,
            costPerSession: 3.0,
            feedAmount: 0,
            waterAmount: 0,
            color: "#4A90E2"
        )

        routines = [feeding, water, cleaning]
        save()
    }

    func reload() { load() }

    func resetAll() {
        routines = []
        UserDefaults.standard.removeObject(forKey: key)
    }

}
