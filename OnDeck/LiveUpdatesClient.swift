import Foundation
import UserNotifications

@MainActor
final class LiveUpdatesClient {
    static let shared = LiveUpdatesClient()

    private var streamTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard

    private var deviceID: String {
        if let existing = defaults.string(forKey: "deviceID"), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        defaults.set(created, forKey: "deviceID")
        return created
    }

    private var baseURL: URL? {
        if let override = defaults.string(forKey: "backendBaseURL"),
           let url = URL(string: override),
           !override.isEmpty {
            return url
        }
        if let bundled = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String,
           let url = URL(string: bundled),
           !bundled.isEmpty {
            return url
        }
        #if DEBUG
        return URL(string: "http://127.0.0.1:8787")
        #else
        return nil
        #endif
    }

    func sync(teams: [String]) async {
        guard let base = baseURL else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationPresenter.shared
        _ = try? await center.requestAuthorization(options: [.alert, .sound])

        guard let registerURL = endpoint(base, "/v1/devices") else { return }
        var request = URLRequest(url: registerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["id": deviceID, "teams": teams]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
        } catch {
            return
        }
        connect(base: base)
    }

    private func endpoint(_ base: URL, _ path: String) -> URL? {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.path = path
        return components?.url
    }

    private func connect(base: URL) {
        streamTask?.cancel()
        let id = deviceID
        streamTask = Task {
            while !Task.isCancelled {
                await readStream(base: base, deviceID: id)
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    private func readStream(base: URL, deviceID: String) async {
        guard let url = endpoint(base, "/v1/devices/\(deviceID)/stream") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 60 * 30
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let raw = String(line.dropFirst(6))
                guard
                    let data = raw.data(using: .utf8),
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let title = json["title"] as? String,
                    let body = json["body"] as? String
                else { continue }
                await present(title: title, body: body)
            }
        } catch {
            return
        }
    }

    private func present(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
