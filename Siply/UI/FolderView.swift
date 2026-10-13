import SwiftUI

/// Выбранная папка: шапка + таблица треков + поиск по ним.
struct FolderView: View {
    @Environment(Library.self) private var library
    @Environment(PlayerModel.self) private var player
    let folder: FolderNode

    @State private var tracks: [Track] = []
    @State private var artwork: Data?
    @State private var search = ""
    @State private var loading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FolderHeader(folder: folder, tracks: tracks, artwork: artwork)
                .padding(24)
            if tracks.isEmpty && !loading {
                ContentUnavailableView("В этой папке нет музыки", systemImage: "music.note")
            } else {
                TrackList(tracks: Track.filter(tracks, query: search), player: player) { track in
                    // Очередь — вся папка в исходном порядке, не отфильтрованная.
                    if let i = tracks.firstIndex(where: { $0.url == track.url }) {
                        player.play(queue: tracks, startingAt: i)
                    }
                }
                .id(folder.url)
            }
        }
        .searchable(text: $search, placement: .toolbar, prompt: "Найти в папке")
        .navigationTitle(folder.name)
        .task(id: "\(folder.url.path)#\(library.generation)") { await load() }
    }

    private func load() async {
        // Сбрасываем состояние предыдущей папки, чтобы оно не мелькало под новой шапкой.
        loading = true
        search = ""
        artwork = nil
        // Сначала имена файлов — таблица видна сразу, теги подъедут следом.
        tracks = LibraryScanner.audioFiles(in: folder.url).map(Track.init)
        let loaded = await LibraryScanner.tracks(in: folder.url)
        // Отменённая (устаревшая) загрузка ничего не пишет.
        guard !Task.isCancelled else { return }
        tracks = loaded
        artwork = LibraryScanner.folderArtwork(for: folder.url, tracks: loaded)
        loading = false
    }
}
