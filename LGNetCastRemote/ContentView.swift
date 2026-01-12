import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.95), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let compact = geo.size.height < 760

                VStack(spacing: compact ? 12 : 16) {
                    header

                    Spacer().frame(height: compact ? 22 : 28)

                    RemoteUI(
                        enabled: model.controlsEnabled,
                        compact: compact,
                        onKey: { model.pressKey($0) }
                    )

                    Spacer(minLength: 0)
                }
                .padding(compact ? 14 : 18)
            }
        }
        .onAppear { model.onAppear() }
        .sheet(isPresented: $model.showIPModal) {
            IPInputSheet(initialIP: model.tvIP, onSave: { model.saveIP($0) })
        }
        .sheet(isPresented: $model.showPinModal) {
            PinInputSheet(onSubmit: { model.submitPin($0) })
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LG Remote")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(model.statusSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            Button { model.showIPModal = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 40, height: 36)
                    .background(.white.opacity(0))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Set IP")
        }
        .padding(14)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// Remote Layout

struct RemoteUI: View {
    let enabled: Bool
    let compact: Bool
    let onKey: (NetCastKey) -> Void

    var body: some View {
        let spacing: CGFloat = compact ? 14 : 16

        let colW: CGFloat = compact ? 96 : 104
        let centerW: CGFloat = compact ? 112 : 120

        let smallH: CGFloat = compact ? 52 : 56
        let rowH: CGFloat = compact ? 56 : 62

        let gapBlockH: CGFloat = compact ? 28 : 40
        let tallH = rowH * 3 + spacing * 2

        let corner: CGFloat = compact ? 18 : 20
        let remoteW = colW + centerW + colW + spacing * 2

        VStack(spacing: spacing) {

            HStack(spacing: spacing) {
                PowerPill(enabled: enabled, height: smallH, corner: corner) { onKey(.power) }
                    .frame(width: colW)

                Color.clear.frame(width: centerW, height: smallH)

                SoftButton(title: "INPUT", enabled: enabled, height: smallH) { onKey(.input) }
                    .frame(width: colW)
            }
            .frame(width: remoteW)

            HStack(spacing: spacing) {
                Color.clear.frame(width: colW, height: gapBlockH)
                Color.clear.frame(width: centerW, height: gapBlockH)
                Color.clear.frame(width: colW, height: gapBlockH)
            }
            .frame(width: remoteW)

            HStack(alignment: .center, spacing: spacing) {
                StepperTall(
                    enabled: enabled,
                    width: colW,
                    height: tallH,
                    topSymbol: "plus",
                    bottomSymbol: "minus",
                    label: "VOL",
                    onTop: { onKey(.volumeUp) },
                    onBottom: { onKey(.volumeDown) }
                )


                VStack(spacing: spacing) {

                    IconWideButton(
                        enabled: enabled,
                        height: rowH,
                        title: "HOME",
                        systemImage: "house.fill",
                        corner: corner
                    ) { onKey(.home) }

                    IconWideButton(
                        enabled: enabled,
                        height: rowH,
                        title: "MUTE",
                        systemImage: "speaker.slash.fill",
                        corner: corner
                    ) { onKey(.mute) }

                    Color.clear.frame(height: rowH)
                }
                .frame(width: centerW)


                StepperTall(
                    enabled: enabled,
                    width: colW,
                    height: tallH,
                    topSymbol: "chevron.up",
                    bottomSymbol: "chevron.down",
                    label: "CH",
                    onTop: { onKey(.channelUp) },
                    onBottom: { onKey(.channelDown) }
                )

            }
            .frame(width: remoteW)

            HStack(spacing: spacing) {
                SoftButton(title: "SETTINGS", enabled: enabled, height: rowH) { onKey(.settings) }
                    .frame(width: colW)

                IconPadButton(enabled: enabled, height: rowH, corner: corner) {
                    onKey(.up)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: compact ? 26 : 30, weight: .semibold))
                }
                .frame(width: centerW)

                SoftButton(title: "INFO", enabled: enabled, height: rowH) { onKey(.info) }
                    .frame(width: colW)
            }
            .frame(width: remoteW)

            HStack(spacing: spacing) {
                IconPadButton(enabled: enabled, height: rowH, corner: corner) {
                    onKey(.left)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: compact ? 26 : 30, weight: .semibold))
                }
                .frame(width: colW)

                OkButton(enabled: enabled, height: rowH, corner: corner) { onKey(.ok) }
                    .frame(width: centerW)

                IconPadButton(enabled: enabled, height: rowH, corner: corner) {
                    onKey(.right)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: compact ? 26 : 30, weight: .semibold))
                }
                .frame(width: colW)
            }
            .frame(width: remoteW)

            HStack(spacing: spacing) {
                SoftButton(title: "BACK", enabled: enabled, height: rowH) { onKey(.back) }
                    .frame(width: colW)

                IconPadButton(enabled: enabled, height: rowH, corner: corner) {
                    onKey(.down)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: compact ? 26 : 30, weight: .semibold))
                }
                .frame(width: centerW)

                SoftButton(title: "EXIT", enabled: enabled, height: rowH) { onKey(.exit) }
                    .frame(width: colW)
            }
            .frame(width: remoteW)

            HStack(spacing: compact ? 16 : 18) {
                ColorPill(enabled: enabled, color: .red) { onKey(.red) }
                ColorPill(enabled: enabled, color: .green) { onKey(.green) }
                ColorPill(enabled: enabled, color: .yellow) { onKey(.yellow) }
                ColorPill(enabled: enabled, color: .blue) { onKey(.blue) }
            }
            .padding(.top, compact ? 22 : 26)
            .frame(width: remoteW)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// Blocks and buttons

struct StepperTall: View {
    let enabled: Bool
    let width: CGFloat
    let height: CGFloat
    let topSymbol: String
    let bottomSymbol: String
    let label: String
    let onTop: () -> Void
    let onBottom: () -> Void

    var body: some View {
        let corner: CGFloat = 20

        VStack(spacing: 0) {
            Button(action: onTop) {
                ZStack {
                    Rectangle().fill(.clear)
                    Image(systemName: topSymbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.35))
                }
            }
            .disabled(!enabled)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: height * 0.42)
            .contentShape(Rectangle())

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(enabled ? 0.85 : 0.35))
                .frame(maxWidth: .infinity)
                .frame(height: height * 0.16)

            Button(action: onBottom) {
                ZStack {
                    Rectangle().fill(.clear)
                    Image(systemName: bottomSymbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.35))
                }
            }
            .disabled(!enabled)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: height * 0.42)
            .contentShape(Rectangle())
        }
        .frame(width: width, height: height)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}



struct SoftButton: View {
    let title: String
    let enabled: Bool
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.5))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct SoftIconButton: View {
    let symbol: String
    let enabled: Bool
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.45))
                .frame(width: size, height: size)
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

struct StepperSegmentButton: View {
    let symbol: String
    let enabled: Bool
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.35))
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}


struct IconWideButton: View {
    let enabled: Bool
    let height: CGFloat
    let title: String
    let systemImage: String
    let corner: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.5))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct IconPadButton<Label: View>: View {
    let enabled: Bool
    let height: CGFloat
    let corner: CGFloat
    let action: () -> Void
    let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.45))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct OkButton: View {
    let enabled: Bool
    let height: CGFloat
    let corner: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(.white.opacity(0.08))
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)

                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 2)
                    .frame(width: height * 0.55, height: height * 0.55)

                Circle()
                    .fill(.white.opacity(enabled ? 0.85 : 0.45))
                    .frame(width: height * 0.18, height: height * 0.18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct PowerPill: View {
    let enabled: Bool
    let height: CGFloat
    let corner: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "power")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(enabled ? 0.95 : 0.5))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(.red.opacity(enabled ? 0.95 : 0.35))
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct ColorPill: View {
    let enabled: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(enabled ? 0.95 : 0.35))
                .frame(height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// Sheets

struct IPInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ip: String
    let onSave: (String) -> Void

    init(initialIP: String, onSave: @escaping (String) -> Void) {
        _ip = State(initialValue: initialIP)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("TV IP address") {
                    TextField("192.162...", text: $ip)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Before connecting, make sure:")
                            .font(.subheadline.weight(.semibold))

                        Text("• The TV is turned on")
                        Text("• The TV allows remote control over network (LG NetCast)")
                        Text("• Your iPhone and TV are on the same Wi-Fi network")
                        Text("• The TV IP address does not change")

                        Divider().padding(.vertical, 6)

                        Text("For a stable connection, reserve the TV IP address in your router (DHCP Reservation).")
                            .font(.footnote)
                            .opacity(0.8)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Set IP")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(ip.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PinInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""
    let onSubmit: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Enter PIN shown on TV") {
                    TextField("PIN", text: $pin)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("TV Pairing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        onSubmit(pin.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview { ContentView() }
