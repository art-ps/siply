import Foundation

/// Открытие аудиофайла извне (Finder): папка файла становится корнем, файл играет с очередью из папки.
@MainActor
enum FileOpener {
    static func open(_ urls: [URL], library: Library, player: PlayerModel) async {
        guard let file = urls.first else { return }
        library.openFolder(of: file)
        let folder = file.deletingLastPathComponent()
        let tracks = await LibraryScanner.tracks(in: folder)
        let target = file.standardizedFileURL
        guard let index = tracks.firstIndex(where: { $0.url.standardizedFileURL == target }) else { return }
        player.play(queue: tracks, startingAt: index)
    }
}
