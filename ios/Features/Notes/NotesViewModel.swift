import Foundation
import SwiftUI

@MainActor
public final class NotesViewModel: ObservableObject {
    @Published public var notes: [Note] = []
    @Published public var searchQuery: String = ""
    @Published public var selectedTag: String? = nil
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public init() {}
    
    public func loadNotes() async {
        isLoading = true
        errorMessage = nil
        do {
            let payload: [String: Any] = [
                "query": searchQuery,
                "tag": selectedTag as Any,
                "pinned_only": false,
                "archived_only": false
            ]
            let res: [Note] = try await GoBridgeService.shared.dispatch(action: "list_notes", payload: payload)
            self.notes = res
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func saveNote(
        id: String?,
        title: String,
        content: String,
        mood: String?,
        isPinned: Bool,
        tags: [String]
    ) async -> Bool {
        do {
            var payload: [String: Any] = [
                "title": title,
                "content": content,
                "mood": mood as Any,
                "is_pinned": isPinned,
                "is_archived": false,
                "tags": tags,
                "note_date": ISO8601DateFormatter().string(from: Date())
            ]
            if let id = id, !id.isEmpty {
                payload["id"] = id
            }
            let _: Note = try await GoBridgeService.shared.dispatch(action: "save_note", payload: payload)
            await loadNotes()
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func deleteNote(id: String) async {
        do {
            let _: Bool = try await GoBridgeService.shared.dispatch(
                action: "delete_note",
                payload: ["id": id]
            )
            await loadNotes()
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
