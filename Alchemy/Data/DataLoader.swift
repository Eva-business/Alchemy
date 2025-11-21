import Foundation

enum DataLoader {
    static func loadElements() -> [Element] {
        guard let url = Bundle.main.url(forResource: "elements", withExtension: "json") else {
            print("elements.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let top = try JSONDecoder().decode([String: [Element]].self, from: data)
            return top["elements"] ?? []
        } catch {
            print("Load error: \(error)")
            return []
        }
    }
}
