import SwiftUI

public struct AddEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600)
    @State private var location: String = ""
    @State private var selectedColor: String = "#5856D6"
    @State private var reminderMinutes: Int = 15
    
    private let colors = ["#5856D6", "#007AFF", "#34C759", "#FF9500", "#FF2D55", "#AF52DE"]
    private let reminderOptions = [0, 5, 15, 30, 60]
    
    public init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }
    
    /// Detect if there's any conflicting event in the selected time window
    private var conflictingEvent: CalendarEvent? {
        viewModel.events.first { event in
            event.startTime < endTime && event.endTime > startTime
        }
    }
    
    private var isTimeValid: Bool {
        endTime > startTime
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detail Agenda")) {
                    TextField("Judul Event (mis. Rapat Anggaran)", text: $title)
                    TextField("Lokasi / Tautan (Opsional)", text: $location)
                }
                
                Section(header: Text("Waktu Pelaksanaan")) {
                    DatePicker("Mulai", selection: $startTime)
                        .onChange(of: startTime) { newStart in
                            if endTime <= newStart {
                                endTime = newStart.addingTimeInterval(3600)
                            }
                        }
                    DatePicker("Selesai", selection: $endTime)
                    
                    // Quick duration chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            durationChip(minutes: 30, label: "+30 Menit")
                            durationChip(minutes: 60, label: "+1 Jam")
                            durationChip(minutes: 120, label: "+2 Jam")
                            Button("Seharian") {
                                setAllDay()
                            }
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "5856D6"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "5856D6").opacity(0.12))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if !isTimeValid {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Waktu selesai harus setelah waktu mulai")
                                .font(LuminaFont.caption())
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Conflict warning banner
                    if let conflict = conflictingEvent {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Potensi Agenda Bentrok")
                                    .font(LuminaFont.caption().weight(.bold))
                                    .foregroundColor(.orange)
                                Text("Bentrok dengan: \"\(conflict.title)\"")
                                    .font(LuminaFont.caption())
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Pengingat")) {
                    Picker("Ingatkan Sebelumnya", selection: $reminderMinutes) {
                        Text("Tidak Ada").tag(0)
                        Text("5 Menit").tag(5)
                        Text("15 Menit").tag(15)
                        Text("30 Menit").tag(30)
                        Text("1 Jam").tag(60)
                    }
                }
                
                Section(header: Text("Warna Label")) {
                    HStack(spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                HapticManager.impact(.light)
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Agenda Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveEvent()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isTimeValid)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func durationChip(minutes: Int, label: String) -> some View {
        Button(action: {
            endTime = startTime.addingTimeInterval(Double(minutes * 60))
            HapticManager.impact(.light)
        }) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "6366F1"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "6366F1").opacity(0.12))
                .cornerRadius(8)
        }
    }
    
    private func setAllDay() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startTime)
        startTime = startOfDay
        endTime = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86400)
        HapticManager.impact(.medium)
    }
    
    private func saveEvent() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, isTimeValid else { return }
        Task {
            let success = await viewModel.createEvent(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                start: startTime,
                end: endTime,
                location: location,
                color: selectedColor,
                reminderMinutes: reminderMinutes
            )
            if success {
                HapticManager.notification(.success)
                dismiss()
            }
        }
    }
}
