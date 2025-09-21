import Foundation

final class EpicDescriptionCache {
    static let shared = EpicDescriptionCache()
    private let key = "epicDescriptions"
    private let defaults = UserDefaults.standard

    private init() {}

    private func loadMap() -> [String: String] {
        guard let data = defaults.data(forKey: key),
            let map = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return map
    }

    private func saveMap(_ map: [String: String]) {
        if let data = try? JSONEncoder().encode(map) {
            defaults.set(data, forKey: key)
        }
    }

    func description(for title: String) -> String? {
        loadMap()[title]
    }

    func setDescription(_ description: String, for title: String) {
        var map = loadMap()
        map[title] = description
        saveMap(map)
    }
}
