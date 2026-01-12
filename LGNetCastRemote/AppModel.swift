import SwiftUI
import Combine

enum ConnectionStatus: Equatable {
    case idle
    case connecting
    case waitingForTvConfirmation
    case connected
    case notReachable
    case error(String)

    var title: String {
        switch self {
        case .idle: return "IP required"
        case .connecting: return "Connecting…"
        case .waitingForTvConfirmation: return "Enter PIN from TV"
        case .connected: return "Connected to TV"
        case .notReachable: return "Not reachable"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

final class AppModel: ObservableObject {
    @AppStorage("tvIP") private var storedIP = ""
    @AppStorage("pairingKey") private var storedPairingKey = ""

    @Published var tvIP = ""
    @Published var pairingKey: String? = nil
    @Published var status: ConnectionStatus = .idle
    @Published var showIPModal = false
    @Published var showPinModal = false
    @Published var showHintAfter30s = false

    private let client = NetCastClient()
    private var task: Task<Void, Never>?
    private var hintTask: Task<Void, Never>?

    var statusSubtitle: String {
        if showHintAfter30s, status != .connected {
            return "TV on? Same Wi-Fi?"
        }
        return status.title
    }

    func onAppear() {
        tvIP = storedIP
        pairingKey = storedPairingKey.isEmpty ? nil : storedPairingKey

        if tvIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            status = .idle
            showIPModal = true
            return
        }
        start()
    }

    func saveIP(_ ip: String) {
        let clean = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        tvIP = clean
        storedIP = clean

        pairingKey = storedPairingKey.isEmpty ? nil : storedPairingKey

        showIPModal = false
        showPinModal = false
        showHintAfter30s = false
        status = .connecting

        start()
    }

    func submitPin(_ pin: String) {
        let clean = pin.trimmingCharacters(in: .whitespacesAndNewlines)
        pairingKey = clean.isEmpty ? nil : clean
        storedPairingKey = clean

        showPinModal = false
        status = .connecting

        start()
    }

    func start() {
        task?.cancel()
        hintTask?.cancel()
        showHintAfter30s = false

        hintTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self else { return }
            await MainActor.run {
                if self.status == .connected { return }
                self.showHintAfter30s = true
                self.objectWillChange.send()
            }
        }

        let ip = tvIP
        let pin = pairingKey

        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await client.connectLoop(
                    ip: ip,
                    pairingKey: pin,
                    statusUpdate: { s in
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            self.status = s

                            if s == .waitingForTvConfirmation {
                                let hasPin = !(self.pairingKey ?? "").isEmpty
                                self.showPinModal = !hasPin
                            } else {
                                self.showPinModal = false
                            }
                        }
                    }
                )
            } catch {
                await MainActor.run {
                    self.status = .error(error.localizedDescription)
                }
            }
        }
    }

    var controlsEnabled: Bool { status == .connected }

    func pressKey(_ key: NetCastKey) {
        guard controlsEnabled else { return }
        let ip = tvIP
        let pin = pairingKey

        Task {
            do {
                try await client.sendKey(ip: ip, pairingKey: pin, key: key)
            } catch {
                await MainActor.run {
                    self.status = .error(error.localizedDescription)
                }
            }
        }
    }
}
