import SwiftUI
import Combine

class PhotoStore: ObservableObject {
    @Published var photos: [PhotoEntry] = []
    private let key = "coopflow_photos"
    
    init() { load() }
    
    func addPhoto(_ photo: PhotoEntry) {
        photos.insert(photo, at: 0)
        save()
    }
    
    func delete(_ id: UUID) {
        photos.removeAll { $0.id == id }
        save()
    }
    
    func photos(for taskId: UUID) -> [PhotoEntry] {
        photos.filter { $0.taskId == taskId }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PhotoEntry].self, from: data) {
            photos = decoded
        }
    }
    
    func reload() { load() }
    func resetAll() {
        photos = []
        UserDefaults.standard.removeObject(forKey: key)
    }
}


class NoteStore: ObservableObject {
    @Published var notes: [NoteEntry] = []
    private let key = "coopflow_notes"

    init() { load() }

    func add(_ note: NoteEntry) {
        notes.insert(note, at: 0)
        save()
    }

    func update(_ note: NoteEntry) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.updatedAt = Date()
            notes[idx] = updated
            save()
        }
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([NoteEntry].self, from: data) {
            notes = decoded
        }
    }
    func reload() { load() }
    func resetAll() {
        notes = []
        UserDefaults.standard.removeObject(forKey: key)
    }
}
