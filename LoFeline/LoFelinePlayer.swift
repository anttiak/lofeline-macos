import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class LoFelinePlayer {
    let stations = Station.all

    private(set) var selectedIndex: Int
    private(set) var volume: Double
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var currentStation: Station { stations[selectedIndex] }

    private let player = AVPlayer()
    private var timeControlObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var connectWatchdog: Task<Void, Never>?

    private let defaults = UserDefaults.standard
    private let stationKey = "selectedStationIndex"
    private let volumeKey = "volume"

    init() {
        let savedIndex = defaults.object(forKey: stationKey) as? Int
        selectedIndex = min(max(savedIndex ?? 0, 0), Station.all.count - 1)

        let savedVolume = defaults.object(forKey: volumeKey) as? Double
        volume = min(max(savedVolume ?? 0.65, 0), 1)

        player.volume = Float(volume)
        player.automaticallyWaitsToMinimizeStalling = true

        // Clear the buffering flag once audio actually starts.
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { observedPlayer, _ in
            let waiting = observedPlayer.timeControlStatus == .waitingToPlayAtSpecifiedRate
            Task { @MainActor [weak self] in
                guard let self, self.isPlaying else { return }
                self.isLoading = waiting
            }
        }
    }

    func toggle() {
        isPlaying ? stop() : play()
    }

    func play() {
        startStream()
    }

    func stop() {
        connectWatchdog?.cancel()
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        isLoading = false
        errorMessage = nil
    }

    func select(_ index: Int) {
        guard index != selectedIndex, stations.indices.contains(index) else { return }
        selectedIndex = index
        defaults.set(index, forKey: stationKey)
        errorMessage = nil
        if isPlaying {
            startStream()
        }
    }

    func setVolume(_ newValue: Double) {
        let clamped = min(max(newValue, 0), 1)
        volume = clamped
        player.volume = Float(clamped)
        defaults.set(clamped, forKey: volumeKey)
    }

    private func startStream() {
        let item = AVPlayerItem(url: currentStation.url)
        itemStatusObservation = item.observe(\.status, options: [.new]) { observedItem, _ in
            let failed = observedItem.status == .failed
            Task { @MainActor [weak self] in
                guard let self, failed else { return }
                self.reportFailure()
            }
        }

        player.replaceCurrentItem(with: item)
        player.volume = Float(volume)
        player.play()
        isPlaying = true
        isLoading = true
        errorMessage = nil
        startWatchdog()
    }

    // If the stream never leaves the buffering state, treat it as unreachable.
    private func startWatchdog() {
        connectWatchdog?.cancel()
        connectWatchdog = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard let self, !Task.isCancelled, self.isPlaying, self.isLoading else { return }
            self.reportFailure()
        }
    }

    private func reportFailure() {
        connectWatchdog?.cancel()
        player.pause()
        player.replaceCurrentItem(with: nil)
        isPlaying = false
        isLoading = false
        errorMessage = "Couldn’t connect. Try again."
    }
}
