import Foundation
import SwiftUI

// JSON 對應的元素 (id 對應 assets 名稱)
struct Element: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let recipes: [[String]]    // recipes: array of [ingredientId, ingredientId]
}

// 在合成區出現的實例（位置會動態變）
struct SynthesisItem: Identifiable {
    let id = UUID()
    var elementId: String
    var position: CGPoint
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
}
