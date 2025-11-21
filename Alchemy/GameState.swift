import Foundation
import Observation
import AVFoundation
import SwiftUI

@Observable
final class GameState {
    // 來自 JSON 的所有元素
    var allElements: [Element] = DataLoader.loadElements()
    
    // 已解鎖的元素 id（初始只有 4 個基礎元素）
    var unlocked: Set<String> = ["water","fire","earth","air"]
    
    // 主列表中顯示（玩家尚可拖出的物質）以保留順序
    var availableList: [String] = ["water","fire","earth","air"]
    
    // 合成區動態實例
    var synthesisItems: [SynthesisItem] = []
    
    // 設定
    var soundOn: Bool = true
    var musicOn: Bool = true
    
    // 計時（遊戲時間，秒）
    var elapsedSeconds: Int = 0
    
    @ObservationIgnored var audioPlayer: AVAudioPlayer? = nil
    @ObservationIgnored var bgAudioPlayer: AVAudioPlayer? = nil
    
    init() {
        // 確保初始可用列表排序（依名稱，若找不到名稱則用 id）
        sortAvailableList()
    }
    
    // MARK: - play sound
    func playCombineSound() {
        guard soundOn else { return }
        if let url = Bundle.main.url(forResource: "pop", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("audio error", error)
            }
        } else {
            print("audio resource not found: pop.wav")
        }
    }
    
    // MARK: - Background Music (bundle: music_bg.mp3)
    func startBackgroundMusic() {
        guard musicOn else { return }
        guard let url = Bundle.main.url(forResource: "music_bg", withExtension: "mp3") else {
            print("Background music resource not found: music_bg.mp3")
            return
        }
        do {
            // Configure audio session to mix with others so it doesn't interrupt other audio
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // loop forever
            player.volume = 0.7
            player.prepareToPlay()
            player.play()
            bgAudioPlayer = player
        } catch {
            print("Failed to start background music:", error)
        }
    }
    
    func stopBackgroundMusic() {
        bgAudioPlayer?.stop()
        bgAudioPlayer = nil
        // You can deactivate the session if you want to fully release audio resources.
        // Do not deactivate if you still need to play short sounds frequently.
        // try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - spawn
    func spawnItem(elementId: String, at position: CGPoint) {
        var item = SynthesisItem(elementId: elementId, position: position)
        item.opacity = 1
        item.scale = 1
        synthesisItems.append(item)
    }
    
    // MARK: - duplicate
    func duplicate(item: SynthesisItem, slightOffset: Bool = true) {
        // 以相同位置（或輕微偏移）複製，並加一個淡入/放大動畫
        let base = item.position
        let pos: CGPoint
        if slightOffset {
            let dx: CGFloat = 10
            let dy: CGFloat = 10
            pos = CGPoint(x: base.x + dx, y: base.y + dy)
        } else {
            pos = base
        }
        
        var newItem = SynthesisItem(elementId: item.elementId, position: pos, scale: 0.1, opacity: 0.0)
        synthesisItems.append(newItem)
        if let idx = synthesisItems.firstIndex(where: { $0.id == newItem.id }) {
            withAnimation(.spring(response: 0.3)) {
                synthesisItems[idx].opacity = 1.0
                synthesisItems[idx].scale = 1.0
            }
        }
    }
    
    // MARK: - 核心：兩物質在「中間點」合成並有動畫
    func tryCombine(itemA: SynthesisItem, itemB: SynthesisItem) {

        // 先複製資料（SwiftUI 一定要這樣才能正確渲染）
        let posA = itemA.position
        let posB = itemB.position
        let idA = itemA.id
        let idB = itemB.id
        let a = itemA.elementId
        let b = itemB.elementId

        guard let product = findProduct(forIngredients: a, and: b) else { return }

        let mid = CGPoint(
            x: (posA.x + posB.x) / 2,
            y: (posA.y + posB.y) / 2
        )

        // 1. 移除舊物品（先動畫）
        withAnimation(.easeInOut(duration: 0.2)) {
            synthesisItems.removeAll { $0.id == idA || $0.id == idB }
        }

        // 2. 延遲一個 RunLoop，再加入產物，讓 SwiftUI 有時間渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {

            // 先小後大
            var newItem = SynthesisItem(elementId: product.id, position: mid)
            newItem.opacity = 0
            newItem.scale = 0.1
            self.synthesisItems.append(newItem)

            // 3. 再跑動畫
            if let idx = self.synthesisItems.firstIndex(where: { $0.id == newItem.id }) {
                withAnimation(.spring(response: 0.35)) {
                    self.synthesisItems[idx].opacity = 1
                    self.synthesisItems[idx].scale = 1.0
                }
            }

            // 4. 解鎖
            if !self.unlocked.contains(product.id) {
                self.unlocked.insert(product.id)
                if !self.availableList.contains(product.id) {
                    self.availableList.append(product.id)
                    self.sortAvailableList()
                } else {
                    // 即使已存在，也確保排序
                    self.sortAvailableList()
                }
            } else {
                // 已解鎖時也確保列表排序一致
                self.sortAvailableList()
            }

            self.playCombineSound()
        }
    }


    // find product
    private func findProduct(forIngredients x: String, and y: String) -> Element? {
        for e in allElements {
            for recipe in e.recipes {
                // recipe 是 [String, String]
                if recipe.count == 2 && ((recipe[0] == x && recipe[1] == y) || (recipe[0] == y && recipe[1] == x)) {
                    return e
                }
            }
        }
        return nil
    }


    // MARK: - 移除用不到的元素
    func removeUnusedMaterialsIfNeeded() {

        var stillNeeded = Set<String>()
        for e in allElements where !unlocked.contains(e.id) {
            for r in e.recipes {
                for ing in r { stillNeeded.insert(ing) }
            }
        }
        
        var toRemove: [String] = []
        
        for id in availableList {
            if unlocked.contains(id) && !stillNeeded.contains(id) {
                toRemove.append(id)
            }
        }
        
        for id in toRemove {
            availableList.removeAll(where: { $0 == id })
            synthesisItems.removeAll(where: { $0.elementId == id })
        }
        
        // 維持排序
        sortAvailableList()
    }
    
    // MARK: - replay
    func resetGame() {
        unlocked = ["water","fire","earth","air"]
        availableList = ["water","fire","earth","air"]
        synthesisItems = []
        elapsedSeconds = 0
        // 重設後也排序（依名稱）
        sortAvailableList()
    }
    
    // MARK: - 排序工具：依元素顯示名稱（fallback 用 id），不分大小寫、本地化比較
    private func sortAvailableList() {
        availableList.sort { lhs, rhs in
            let lName = allElements.first(where: { $0.id == lhs })?.name ?? lhs
            let rName = allElements.first(where: { $0.id == rhs })?.name ?? rhs
            return lName.localizedCaseInsensitiveCompare(rName) == .orderedAscending
        }
    }
}

