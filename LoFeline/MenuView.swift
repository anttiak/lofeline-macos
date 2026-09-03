import SwiftUI
import AppKit

struct MenuView: View {
    let player: LoFelinePlayer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let error = player.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.42))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            }
            separator
            Text("Stations")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 3)

            ForEach(Array(player.stations.enumerated()), id: \.element.id) { index, station in
                StationRow(
                    station: station,
                    isSelected: index == player.selectedIndex,
                    action: { player.select(index) }
                )
            }

            separator
            volumeControls
            separator
            MenuActionRow(title: "Quit", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(6)
        .frame(width: 264)
        .background(Palette.surface)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Button(action: player.toggle) {
                CatArtView(playing: player.isPlaying)
                    .frame(width: 26, height: 23)
            }
            .buttonStyle(CatButtonStyle())
            .help(player.isPlaying ? "Pause" : "Play")

            Text("LoFeline")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.text)

            Spacer(minLength: 0)

            if player.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 5)
        .padding(.bottom, 7)
    }

    private var volumeControls: some View {
        HStack(spacing: 9) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)

            Slider(
                value: Binding(get: { player.volume }, set: { player.setVolume($0) }),
                in: 0...1
            )
            .tint(Palette.accent)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundStyle(Palette.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 3)
        .padding(.bottom, 6)
    }

    private var separator: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(height: 0.5)
            .padding(.vertical, 5)
    }
}

/// Raised, beveled style for the cat play/pause button; pressing sinks it in.
private struct CatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Palette.hover.opacity(configuration.isPressed ? 0.5 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.black.opacity(0.30)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.35),
                    radius: configuration.isPressed ? 0 : 1,
                    y: configuration.isPressed ? 0 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct MenuActionRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 11))
                .frame(width: 11)
            Text(title)
                .font(.system(size: 13))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Palette.text)
        .frame(height: 26)
        .padding(.horizontal, 8)
        .background(isHovering ? Palette.hover : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { isHovering = $0 }
    }
}

private struct StationRow: View {
    let station: Station
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 11)
                .opacity(isSelected ? 1 : 0)

            Text(station.displayName)
                .font(.system(size: 13))
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .foregroundStyle(isSelected ? Color.white : Palette.text)
        .frame(height: 26)
        .padding(.horizontal, 8)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { isHovering = $0 }
        .help(station.note)
    }

    private var rowBackground: Color {
        if isSelected { return Palette.accent }
        return isHovering ? Palette.hover : .clear
    }
}
