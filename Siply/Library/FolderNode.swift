import Foundation

/// Папка в дереве сайдбара. Дети — только подпапки, читаются с диска при первом обращении.
final class FolderNode: Identifiable, Hashable {
    let url: URL
    var id: URL { url }
    var name: String { url.lastPathComponent }

    private var cachedChildren: [FolderNode]??

    init(url: URL) {
        self.url = url.standardizedFileURL
    }

    /// nil — подпапок нет: у строки в сайдбаре не будет стрелки раскрытия.
    var children: [FolderNode]? {
        if let cached = cachedChildren { return cached }
        let subs = FolderNode.subfolders(of: url)
        let result: [FolderNode]? = subs.isEmpty ? nil : subs.map(FolderNode.init)
        cachedChildren = .some(result)
        return result
    }

    /// Видимые подпапки, отсортированные как в Finder.
    static func subfolders(of url: URL) -> [URL] {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else {
            NSLog("Siply: не удалось прочитать папку %@", url.path)
            return []
        }
        return items
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func == (a: FolderNode, b: FolderNode) -> Bool { a.url == b.url }
    func hash(into hasher: inout Hasher) { hasher.combine(url) }
}
