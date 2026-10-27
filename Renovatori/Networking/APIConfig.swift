import Foundation

/// Base URL of the Renovatori JSON API (`/api/v1`) for the current build configuration.
enum APIConfig {
    #if DEBUG
    /// Local backend. Reachable from the simulator; a real device needs the Mac's LAN IP or a tunnel.
    /// Override with the `API_ORIGIN` launch environment variable (e.g. `http://192.168.1.10:3000`).
    static let origin = ProcessInfo.processInfo.environment["API_ORIGIN"].flatMap(URL.init(string:))
        ?? URL(string: "http://localhost:3000")!
    #else
    static let origin = URL(string: "https://renovatori.ge")!
    #endif

    static let baseURL = origin.appending(path: "api/v1")

    /// Turns a relative upload path from the API (`/uploads/small/abc.jpg`) into a loadable URL.
    /// Image paths are relative to the origin, not to `/api/v1`.
    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return origin.appending(path: path)
    }
}
