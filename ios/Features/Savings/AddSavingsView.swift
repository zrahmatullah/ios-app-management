import SwiftUI

public struct AddSavingsView: View {
    @ObservedObject var viewModel: SavingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var targetAmountString: String = ""
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var selectedIcon: String = "gift.fill"
    @State private var selectedColor: String = "#FF9500"
    
    private let availableIcons = ["gift.fill", "shield.checkerboard", "airplane", "car.fill", "house.fill", "laptopcomputer", "cart.fill", "heart.fill"]
    private let availableColors = ["#FF9500", "#34C759", "#007AFF", "#AF52DE", "#FF2D55", "#5856D6"]
    
    public init(viewModel: SavingsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informasi Celengan")) {
                    TextField("Nama Celengan (mis. Dana Darurat)", text: $name)
                    
                    HStack {
                        Text("Target (Rp)")
                        Spacer()
                        TextField("0", text: $targetAmountString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Batas Waktu", selection: $deadline, displayedComponents: .date)
                }
                
                Section(header: Text("Ikon & Warna")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color.primary.opacity(0.08))
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .shadow(radius: selectedColor == color ? 4 : 0)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Celengan Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveSavings()
                    }
                    .disabled(name.isEmpty || targetAmountString.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveSavings() {
        guard let target = Int64(targetAmountString.replacingOccurrences(of: ".", with: "")) else { return }
        Task {
            let success = await viewModel.createSavings(
                name: name,
                target: target,
                deadline: deadline,
                icon: selectedIcon,
                color: selectedColor
            )
            if success {
                dismiss()
            }
        }
    }
}
