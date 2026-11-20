import SwiftUI

public struct NoteEditorView: View {
    @ObservedObject var viewModel: NotesViewModel
    let existingNote: Note?
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedMood: String = "😊"
    @State private var isPinned: Bool = false
    @State private var tagsString: String = ""
    
    private let moods = ["😊", "😌", "🚀", "💡", "😴", "😔", "🔥", "✨"]
    
    public init(viewModel: NotesViewModel, existingNote: Note?) {
        self.viewModel = viewModel
        self.existingNote = existingNote
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Suasana Hati (Mood)")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(moods, id: \.self) { mood in
                                Button(action: {
                                    HapticManager.impact(.light)
                                    selectedMood = mood
                                }) {
                                    Text(mood)
                                        .font(.system(size: 26))
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(selectedMood == mood ? Color(hex: "6366F1").opacity(0.2) : Color.clear)
                                        )
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Catatan")) {
                    TextField("Judul Catatan", text: $title)
                        .font(LuminaFont.headline())
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .font(LuminaFont.body())
                }
                
                Section(header: Text("Label & Pin")) {
                    TextField("Tag (pisahkan dengan koma, mis. Keuangan, Ide)", text: $tagsString)
                    Toggle("Sematkan di Atas (Pin)", isOn: $isPinned)
                }
            }
            .navigationTitle(existingNote == nil ? "Tulis Catatan" : "Edit Catatan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveNote()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let note = existingNote {
                    title = note.title
                    content = note.content
                    selectedMood = note.mood ?? "😊"
                    isPinned = note.isPinned
                    tagsString = (note.tags ?? []).joined(separator: ", ")
                }
            }
        }
    }
    
    private func saveNote() {
        let tags = tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        Task {
            let success = await viewModel.saveNote(
                id: existingNote?.id,
                title: title.isEmpty ? "Catatan Baru" : title,
                content: content,
                mood: selectedMood,
                isPinned: isPinned,
                tags: tags
            )
            if success {
                dismiss()
            }
        }
    }
}
