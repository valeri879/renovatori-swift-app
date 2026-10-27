import Foundation

/// Backend the app talks to. Debug builds can switch it from the footer; release builds always use production.
enum APIEnvironment: String, CaseIterable, Identifiable {
    case local, production

    static let storageKey = "apiEnvironment"

    var id: String { rawValue }

    /// The choice saved by the footer switch (debug builds only).
    static var current: APIEnvironment {
        #if DEBUG
        UserDefaults.standard.string(forKey: storageKey).flatMap(APIEnvironment.init(rawValue:)) ?? .local
        #else
        .production
        #endif
    }

    var origin: URL {
        switch self {
        case .local:
            // Reachable from the simulator; a real device needs the Mac's Bonjour name or LAN IP.
            // The shared scheme sets the `API_ORIGIN` launch environment variable (`http://mac.local:3000`),
            // which only applies when the app is started from Xcode.
            ProcessInfo.processInfo.environment["API_ORIGIN"].flatMap(URL.init(string:))
                ?? URL(string: "http://localhost:3000")!
        case .production:
            URL(string: "https://renovatori.ge")!
        }
    }
}

/// Base URL of the Renovatori JSON API (`/api/v1`) for the selected environment.
enum APIConfig {
    static var origin: URL { APIEnvironment.current.origin }

    static var baseURL: URL { origin.appending(path: "api/v1") }

    /// Turns a relative upload path from the API (`/uploads/small/abc.jpg`) into a loadable URL.
    /// Image paths are relative to the origin, not to `/api/v1`.
    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return origin.appending(path: path)
    }
}
