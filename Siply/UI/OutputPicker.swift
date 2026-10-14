import SwiftUI

/// Кнопка выбора устройства вывода, как AirPlay в Apple Music. Системный выход не меняет.
struct OutputPicker: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        Menu {
            item("Как в системе", device: nil)
            Divider()
            ForEach(player.availableOutputs) { item($0.name, device: $0) }
            if let o = player.output, !player.availableOutputs.contains(o) {
                Divider()
                Toggle("\(o.name) — не подключено", isOn: .constant(true)).disabled(true)
            }
        } label: {
            Image(systemName: player.output == nil ? "hifispeaker" : "hifispeaker.fill")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Устройство вывода: \(player.output?.name ?? "как в системе")")
        .accessibilityLabel("Устройство вывода")
        .accessibilityValue(player.output?.name ?? "Как в системе")
    }

    private func item(_ title: String, device: OutputDevice?) -> some View {
        Toggle(title, isOn: Binding(
            get: { player.output?.uid == device?.uid },
            set: { if $0 { player.output = device } }))
    }
}
