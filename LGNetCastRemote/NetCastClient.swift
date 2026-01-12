import Foundation

enum NetCastKey {
    case up, down, left, right, ok
    case back, exit
    case volumeUp, volumeDown, mute
    case channelUp, channelDown
    case input
    case power
    case home, settings, info
    case red, green, yellow, blue
}


final class NetCastClient {
    private let port = 8080

    func connectLoop(
        ip: String,
        pairingKey: String?,
        statusUpdate: @escaping (ConnectionStatus) -> Void
    ) async throws {

        var backoffMs = 300

        while !Task.isCancelled {
            do {
                if let pin = pairingKey, !pin.isEmpty {
                    if await pingAuthorized(ip: ip, token: pin) {
                        statusUpdate(.connected)
                        backoffMs = 300
                        try await Task.sleep(nanoseconds: 1_500_000_000)
                        continue
                    }
                }

                statusUpdate(.connecting)
                let hs = try await handshake(ip: ip, pin: pairingKey)

                switch hs {
                case .connected:
                    statusUpdate(.connected)
                    backoffMs = 300
                    try await Task.sleep(nanoseconds: 800_000_000)

                case .needPin:
                    statusUpdate(.waitingForTvConfirmation)
                    return
                }
            } catch {
                statusUpdate(.connecting)
                try await Task.sleep(nanoseconds: UInt64(backoffMs) * 1_000_000)
                backoffMs = min(backoffMs * 2, 5000)
            }
        }
    }

    func sendKey(ip: String, pairingKey: String?, key: NetCastKey) async throws {
        let xml =
        """
        <?xml version="1.0" encoding="utf-8"?>
        <command><name>HandleKeyInput</name><value>\(map(key))</value></command>
        """
        _ = try await post(ip, "/udap/api/command", pairingKey, xml)
    }

    private enum HS { case connected, needPin }

    private func handshake(ip: String, pin: String?) async throws -> HS {
        if let pin, !pin.isEmpty {
            let xml = "<?xml version=\"1.0\"?><auth><type>AuthReq</type><value>\(pin)</value></auth>"
            let (code, _) = try await post(ip, "/udap/api/pairing", nil, xml)
            return code == 200 ? .connected : .needPin
        } else {
            let xml = "<?xml version=\"1.0\"?><auth><type>AuthKeyReq</type></auth>"
            _ = try await post(ip, "/udap/api/pairing", nil, xml)
            return .needPin
        }
    }

    private func pingAuthorized(ip: String, token: String) async -> Bool {
        do {
            var req = URLRequest(url: URL(string: "http://\(ip):\(port)/udap/api/data?target=volume_info")!)
            req.httpMethod = "GET"
            req.timeoutInterval = 1.5
            req.setValue(token, forHTTPHeaderField: "X-Auth-Token")
            let (_, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            return code == 200
        } catch {
            return false
        }
    }

    private func post(_ ip: String, _ path: String, _ token: String?, _ xml: String) async throws -> (Int, String) {
        var r = URLRequest(url: URL(string: "http://\(ip):\(port)\(path)")!)
        r.httpMethod = "POST"
        r.httpBody = xml.data(using: .utf8)
        r.timeoutInterval = 2.0
        r.setValue("application/atom+xml", forHTTPHeaderField: "Content-Type")
        if let token { r.setValue(token, forHTTPHeaderField: "X-Auth-Token") }
        let (d, resp) = try await URLSession.shared.data(for: r)
        return ((resp as? HTTPURLResponse)?.statusCode ?? -1, String(data: d, encoding: .utf8) ?? "")
    }

    private func map(_ k: NetCastKey) -> Int {
        switch k {
        case .up: return 12
        case .down: return 13
        case .left: return 14
        case .right: return 15
        case .ok: return 20
            
        case .home: return 21
        case .settings: return 22
        case .info: return 45

        case .back: return 23
        case .exit: return 412

        case .volumeUp: return 24
        case .volumeDown: return 25
        case .mute: return 26

        case .channelUp: return 27
        case .channelDown: return 28

        case .input: return 47
        case .power: return 1

        case .red: return 403
        case .green: return 404
        case .yellow: return 405
        case .blue: return 406
        }
    }
}
