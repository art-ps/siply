import AppKit
import Observation

/// Корневая папка и выбранная папка. Корень запоминается bookmark'ом в UserDefaults.
@MainActor
@Observable
final class Library {
    private(set) var root: FolderNode?
    var selection: FolderNode?
    /// Растёт при rescan — чтобы список треков перечитался даже для той же папки.
    private(set) var generation = 0

    @ObservationIgnored private let defaults: UserDefaults
    private static let bookmarkKey = "rootBookmark"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restore()
    }

    func open(_ url: URL) {
        let node = FolderNode(url: url)
        root = node
        selection = node
        defaults.set(try? url.bookmarkData(), forKey: Self.bookmarkKey)
    }

    /// Папка файла становится корнем. Уже корень → дерево не трогаем, только выбираем его.
    func openFolder(of file: URL) {
        let folder = file.deletingLastPathComponent()
        if let root, root.url.standardizedFileURL == folder.standardizedFileURL {
            selection = root
        } else {
            open(folder)
        }
    }

    /// Пересобирает дерево от корня; выбор остаётся на той же папке.
    func rescan() {
        guard let root else { return }
        let selected = selection?.url
        self.root = FolderNode(url: root.url)
        selection = selected.map(FolderNode.init)
        generation += 1
    }

    /// Корень из bookmark'а. Нет, устарел или папки больше нет → без корня.
    func restore() {
        guard let data = defaults.data(forKey: Self.bookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale),
              FileManager.default.fileExists(atPath: url.path)
        else { root = nil; selection = nil; return }
        open(url)
    }

    func openFolderPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Открыть"
        panel.message = "Выберите папку с музыкой"
        if panel.runModal() == .OK, let url = panel.url { open(url) }
    }
}
