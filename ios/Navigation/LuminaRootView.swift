import SwiftUI

public struct LuminaRootView: View {
    @State private var selectedTab: Int = 0
    @State private var showingQuickAddActionSheet: Bool = false
    
    // Quick add sheet states
    @State private var showingQuickAddTx: Bool = false
    @State private var showingQuickAddNote: Bool = false
    @State private var showingQuickAddEvent: Bool = false
    
    // Shared view models for quick adds
    @StateObject private var financeVM = FinanceViewModel()
    @StateObject private var notesVM = NotesViewModel()
    @StateObject private var calendarVM = CalendarViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Tab View
            Group {
                switch selectedTab {
                case 0:
                    DashboardView(selectedTab: $selectedTab)
                case 1:
                    FinanceView()
                case 2:
                    GoalsView()
                case 3:
                    CalendarView()
                case 4:
                    SettingsView()
                default:
                    DashboardView(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Floating Tab Bar
            LuminaTabBar(selectedTab: $selectedTab) {
                showingQuickAddActionSheet = true
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .confirmationDialog("Tambah Cepat", isPresented: $showingQuickAddActionSheet, titleVisibility: .visible) {
            Button("Tambah Transaksi") {
                showingQuickAddTx = true
            }
            Button("Tambah Catatan / Jurnal") {
                showingQuickAddNote = true
            }
            Button("Tambah Jadwal / Event") {
                showingQuickAddEvent = true
            }
            Button("Batal", role: .cancel) {}
        }
        .sheet(isPresented: $showingQuickAddTx) {
            AddTransactionView(viewModel: financeVM)
        }
        .sheet(isPresented: $showingQuickAddNote) {
            NoteEditorView(viewModel: notesVM, existingNote: nil)
        }
        .sheet(isPresented: $showingQuickAddEvent) {
            AddEventView(viewModel: calendarVM)
        }
    }
}
