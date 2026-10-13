import AppKit
import MediaPlayer
import Observation

/// Control Center / медиаклавиши: команды → PlayerModel, состояние → MPNowPlayingInfoCenter.
@MainActor
final class NowPlaying {
    private let player: PlayerModel
    private var artworkURL: URL?
    private var artwork: MPMediaItemArtwork?

    init(player: PlayerModel) {
        self.player = player
        let center = MPRemoteCommandCenter.shared()
        for command in [center.playCommand, center.pauseCommand, center.togglePlayPauseCommand,
                        center.nextTrackCommand, center.previousTrackCommand] {
            command.isEnabled = true
        }
        center.changePlaybackPositionCommand.isEnabled = true
        center.playCommand.addTarget { [player] _ in
            Task { @MainActor in if !player.isPlaying { player.togglePlayPause() } }
            return .success
        }
        center.pauseCommand.addTarget { [player] _ in
            Task { @MainActor in if player.isPlaying { player.togglePlayPause() } }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [player] _ in
            Task { @MainActor in player.togglePlayPause() }
            return .success
        }
        center.nextTrackCommand.addTarget { [player] _ in
            Task { @MainActor in player.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [player] _ in
            Task { @MainActor in player.previous() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [player] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            Task { @MainActor in player.seek(to: position) }
            return .success
        }
        observe()
    }

    /// Перепубликует состояние при каждом изменении наблюдаемых полей плеера.
    private func observe() {
        withObservationTracking {
            publish()
        } onChange: {
            Task { @MainActor [weak self] in self?.observe() }
        }
    }

    private func publish() {
        let center = MPNowPlayingInfoCenter.default()
        guard let track = player.currentTrack else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
        ]
        if let art = artwork(for: track) { info[MPMediaItemPropertyArtwork] = art }
        center.nowPlayingInfo = info
        center.playbackState = player.isPlaying ? .playing : .paused
    }

    /// Обложку собираем один раз на трек, не каждые полсекунды.
    private func artwork(for track: Track) -> MPMediaItemArtwork? {
        if artworkURL == track.url { return artwork }
        artworkURL = track.url
        artwork = track.artwork.flatMap(NSImage.init(data:)).map { image in
            MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        return artwork
    }
}
