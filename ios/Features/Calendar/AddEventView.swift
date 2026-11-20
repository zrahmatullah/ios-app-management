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
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detail Agenda")) {
                    TextField("Judul Event", text: $title)
                    TextField("Lokasi (Opsional)", text: $location)
                }
                
                Section(header: Text("Waktu")) {
                    DatePicker("Mulai", selection: $startTime)
                    DatePicker("Selesai", selection: $endTime)
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
                            Button(action: { selectedColor = color }) {
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
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveEvent() {
        Task {
            let success = await viewModel.createEvent(
                title: title,
                start: startTime,
                end: endTime,
                location: location,
                color: selectedColor,
                reminderMinutes: reminderMinutes
            )
            if success {
                dismiss()
            }
        }
    }
}
