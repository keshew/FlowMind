import SwiftUI
import Foundation

// MARK: - Bird Types
enum BirdType: String, CaseIterable, Codable {
    case chicken = "Chickens"
    case duck = "Ducks"
    case goose = "Geese"
    case turkey = "Turkeys"
    case quail = "Quails"
    case pigeon = "Pigeons"
    case parrot = "Parrots"
    case other = "Other"

    var icon: String {
        switch self {
        case .chicken: return "🐔"
        case .duck: return "🦆"
        case .goose: return "🦢"
        case .turkey: return "🦃"
        case .quail: return "🐦"
        case .pigeon: return "🕊️"
        case .parrot: return "🦜"
        case .other: return "🐣"
        }
    }
}

// MARK: - Routine Model
struct Routine: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var category: RoutineCategory
    var steps: [RoutineStep]
    var schedule: RoutineSchedule
    var estimatedMinutes: Int
    var costPerSession: Double
    var feedAmount: Double // grams
    var waterAmount: Double // liters
    var isActive: Bool = true
    var createdAt: Date = Date()
    var color: String = "#4A90E2"
}

enum RoutineCategory: String, CaseIterable, Codable {
    case feeding = "Feeding"
    case cleaning = "Cleaning"
    case water = "Water Check"
    case health = "Health"
    case other = "Other"

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .cleaning: return "sparkles"
        case .water: return "drop.fill"
        case .health: return "heart.fill"
        case .other: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .feeding: return "#FF9F5A"
        case .cleaning: return "#4A90E2"
        case .water: return "#5BA3F5"
        case .health: return "#FF6B6B"
        case .other: return "#FFC933"
        }
    }
}

struct RoutineStep: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var estimatedMinutes: Int
    var isRequired: Bool = true
}

struct RoutineSchedule: Codable {
    var frequency: ScheduleFrequency
    var times: [String] // "08:00", "18:00"
    var daysOfWeek: [Int] // 0=Sun, 1=Mon, etc.
    var startDate: Date = Date()
}

enum ScheduleFrequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom = "Custom"
    case weekly = "Weekly"
}

// MARK: - Task Model
struct DailyTask: Identifiable, Codable {
    var id: UUID = UUID()
    var routineId: UUID
    var routineName: String
    var routineIcon: String
    var routineCategory: RoutineCategory
    var scheduledTime: String
    var scheduledDate: Date
    var status: TaskStatus = .pending
    var completedAt: Date?
    var actualMinutes: Int?
    var notes: String = ""
    var photoIds: [UUID] = []
    var steps: [TaskStepCompletion] = []
}

enum TaskStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case missed = "Missed"
    case skipped = "Skipped"
}

struct TaskStepCompletion: Identifiable, Codable {
    var id: UUID = UUID()
    var stepId: UUID
    var stepTitle: String
    var isCompleted: Bool = false
    var completedAt: Date?
}

// MARK: - Photo Model
struct PhotoEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var taskId: UUID?
    var routineName: String
    var imageData: Data
    var caption: String
    var createdAt: Date = Date()
}

// MARK: - Note Model
struct NoteEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var taskId: UUID?
    var routineName: String?
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - Analytics Model
struct DayStats: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var totalTasks: Int
    var completedTasks: Int
    var missedTasks: Int
    var totalMinutes: Int
    var totalCost: Double
    var totalFeedGrams: Double
    var totalWaterLiters: Double
}

// MARK: - Suggestion Model
struct Suggestion: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var type: SuggestionType
    var icon: String
    var isApplied: Bool = false
}

enum SuggestionType: String {
    case merge = "Merge Tasks"
    case reschedule = "Reschedule"
    case automate = "Automate"
    case reduce = "Reduce Effort"
}
