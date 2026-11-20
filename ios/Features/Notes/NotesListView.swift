import SwiftUI

public struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingAddNote: Bool = false
    @State private var selectedNoteForEdit: Note? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Cari catatan atau jurnal (FTS5)...", text: $viewModel.searchQuery)
                            .onChange(of: viewModel.searchQuery) { _ in
                                Task { await viewModel.loadNotes() }
                            }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Notes List
                    if !viewModel.notes.isEmpty {
                        ForEach(viewModel.notes) { note in
                            Button(action: {
                                selectedNoteForEdit = note
                            }) {
                                LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            if let mood = note.mood, !mood.isEmpty {
                                                Text(mood)
                                                    .font(.system(size: 20))
                                            }
                                            Text(note.title)
                                                .font(LuminaFont.headline())
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if note.isPinned {
                                                Image(systemName: "pin.fill")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Color(hex: "F59E0B"))
                                            }
                                        }
                                        
                                        Text(note.content)
                                            .font(LuminaFont.subheadline())
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack {
                                            Text(note.noteDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(LuminaFont.caption())
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            if let tags = note.tags, !tags.isEmpty {
                                                HStack(spacing: 6) {
                                                    ForEach(tags, id: \.self) { tag in
                                                        Text("#\(tag)")
                                                            .font(LuminaFont.caption().weight(.medium))
                                                            .foregroundColor(Color(hex: "6366F1"))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteNote(id: note.id) }
                                } label: {
                                    Label("Hapus Catatan", systemImage: "trash")
                                }
                            }
                        }
                    } else {
                        LuminaEmptyStateView(
                            icon: "note.text",
                            title: "Belum Ada Catatan",
                            message: "Tuliskan ide, pikiran, dan refleksi harian Anda.",
                            actionTitle: "Tulis Sekarang"
                        ) {
                            showingAddNote = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Catatan Harian")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        showingAddNote = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                NoteEditorView(viewModel: viewModel, existingNote: nil)
            }
            .sheet(item: $selectedNoteForEdit) { note in
                NoteEditorView(viewModel: viewModel, existingNote: note)
            }
            .task {
                await viewModel.loadNotes()
            }
            .refreshable {
                await viewModel.loadNotes()
            }
        }
    }
}
