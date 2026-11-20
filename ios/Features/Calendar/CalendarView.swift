import SwiftUI

public struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingAddEvent: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Interactive Date Picker Calendar
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 14) {
                        DatePicker(
                            "Pilih Tanggal",
                            selection: $viewModel.selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(Color(hex: "6366F1"))
                    }
                    
                    // Selected Day Agenda
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Agenda: \(viewModel.selectedDate.formatted(date: .complete, time: .omitted))")
                                .font(LuminaFont.headline())
                            Spacer()
                        }
                        
                        if !viewModel.eventsForSelectedDate.isEmpty {
                            ForEach(viewModel.eventsForSelectedDate) { event in
                                LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                                    HStack(spacing: 12) {
                                        Rectangle()
                                            .fill(Color(hex: event.color))
                                            .frame(width: 4)
                                            .cornerRadius(2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.title)
                                                .font(LuminaFont.headline())
                                            Text("\(event.startTime.formatted(date: .omitted, time: .shortened)) - \(event.endTime.formatted(date: .omitted, time: .shortened))\(event.location.isEmpty ? "" : " • \(event.location)")")
                                                .font(LuminaFont.caption())
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteEvent(id: event.id) }
                                    } label: {
                                        Label("Hapus Event", systemImage: "trash")
                                    }
                                }
                            }
                        } else {
                            LuminaEmptyStateView(
                                icon: "calendar.badge.clock",
                                title: "Tidak Ada Agenda",
                                message: "Jadwal Anda kosong pada hari ini.",
                                actionTitle: "Tambah Agenda"
                            ) {
                                showingAddEvent = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Kalender")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadEvents()
            }
            .refreshable {
                await viewModel.loadEvents()
            }
        }
    }
}
