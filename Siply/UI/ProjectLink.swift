import SwiftUI

/// «проект vibecoded.ru» в правой части тулбара; vibecoded.ru — ссылка.
struct ProjectLink: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("проект")
                .foregroundStyle(.secondary)
            Link("vibecoded.ru", destination: URL(string: "https://vibecoded.ru")!)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor)
                .help("https://vibecoded.ru")
        }
        .font(.callout)
        .fixedSize(horizontal: true, vertical: false)
    }
}
