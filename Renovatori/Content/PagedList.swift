import Foundation

/// Loads a paginated list endpoint page by page and appends as the user scrolls.
/// `Item` is `Sendable` so its `Decodable` conformance can be used inside the `APIClient` actor.
@MainActor
final class PagedList<Item: Decodable & Identifiable & Sendable>: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    /// Error of the last request; shown full-screen when there are no items yet.
    @Published private(set) var error: APIError?

    private let path: String
    private let pageSize: Int
    private var requiresAuth: Bool
    private var extraQuery: [URLQueryItem]
    private var pagination: Pagination?
    private var hasLoaded = false

    init(path: String, pageSize: Int = 12, query: [URLQueryItem] = [], requiresAuth: Bool = false) {
        self.path = path
        self.pageSize = pageSize
        self.requiresAuth = requiresAuth
        self.extraQuery = query
    }

    var hasNext: Bool { pagination?.hasNext ?? false }

    /// Total number of items on the server for the current query, once a page has loaded.
    var totalItems: Int? { pagination?.totalItems }

    /// True once the first page came back without items.
    var isEmpty: Bool { hasLoaded && items.isEmpty && error == nil }

    /// First load when the screen appears; later appearances keep the list.
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    /// Drops one item locally (e.g. after deleting it on the server) without reloading.
    func remove(id: Item.ID) {
        items.removeAll { $0.id == id }
    }

    /// Replaces the list with page 1 (pull-to-refresh, sort change, retry). `requiresAuth` switches
    /// whether the token is sent, for public lists that show signed-in users more.
    func reload(query: [URLQueryItem]? = nil, requiresAuth: Bool? = nil) async {
        if let query {
            extraQuery = query
        }
        if let requiresAuth {
            self.requiresAuth = requiresAuth
        }
        await load(page: 1, replacing: true)
    }

    /// Fetches the next page when `item` is one of the last rows on screen.
    func loadMoreIfNeeded(after item: Item) async {
        guard hasNext, !isLoading, let pagination else { return }
        let thresholdIndex = items.index(items.endIndex, offsetBy: -3, limitedBy: items.startIndex) ?? items.startIndex
        guard let index = items.firstIndex(where: { $0.id == item.id }), index >= thresholdIndex else { return }
        await load(page: pagination.currentPage + 1, replacing: false)
    }

    private func load(page: Int, replacing: Bool) async {
        guard !isLoading || replacing else { return }
        isLoading = true
        defer { isLoading = false }

        let query = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ] + extraQuery

        do {
            let response: PagedResponse<Item> = try await APIClient.shared.sendPaged(
                Endpoint(method: .get, path: path, query: query, requiresAuth: requiresAuth)
            )
            if replacing {
                items = response.data
            } else {
                // A refresh between pages can shift items; skip any already shown.
                let shownIDs = Set(items.map(\.id))
                items += response.data.filter { !shownIDs.contains($0.id) }
            }
            pagination = response.pagination
            error = nil
            hasLoaded = true
        } catch is CancellationError {
            // The view went away mid-request (or a newer refresh replaced it).
        } catch let apiError as APIError {
            error = apiError
            hasLoaded = true
        } catch {
            self.error = .network
            hasLoaded = true
        }
    }
}

/// State of a screen that loads one resource.
enum Loadable<Value> {
    case loading
    case loaded(Value)
    case failed(APIError)
}

extension APIError {
    var isNotFound: Bool { status == 404 || code == "not_found" }
}
