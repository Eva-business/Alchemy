import SwiftUI

// 當合成區中兩個物質重疊到達一定比例時，可以互相合成的兩物質就會進行合成，
// 並在原地產生合成物質（兩原物質消失，不論該合成物是否為新解鎖）

struct MainGameView: View {
    @Environment(GameState.self) var gameState
    
    // local geometry space
    @State private var synthAreaSize: CGSize = .zero
    // currently dragging item id to render on top
    @State private var draggingItemID: UUID? = nil
    
    // 合成門檻（可依需求調整）
    private let overlapThreshold: CGFloat = 0.2      // 交疊比例門檻
    private let proximityThreshold: CGFloat = 40.0   // 中心距離門檻（pt）
    
    var body: some View {
        HStack() {
            // 左：合成區
            ZStack {
                // 淺綠色背景，保留外框與標籤
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.secondary, lineWidth: 1)
                    )
                    .overlay(Text("合成區").font(.caption).padding(), alignment: .top)
                
                GeometryReader { geo in
                    ZStack {
                        // Draw non-dragging items first
                        ForEach(gameState.synthesisItems.filter { $0.id != draggingItemID }) { item in
                            SynthesisItemView(item: item)
                                .position(item.position) // item.position is page coords inside synth area
                                .gesture(dragGesture(for: item, in: geo))
                                .onTapGesture(count: 2) {
                                    gameState.duplicate(item: item)
                                }
                                .id(item.id)
                        }
                        // Draw dragging item last (on top)
                        if let draggingID = draggingItemID,
                           let draggingItem = gameState.synthesisItems.first(where: { $0.id == draggingID }) {
                            SynthesisItemView(item: draggingItem)
                                .position(draggingItem.position)
                                .gesture(dragGesture(for: draggingItem, in: geo))
                                .onTapGesture(count: 2) {
                                    gameState.duplicate(item: draggingItem)
                                }
                                .id(draggingItem.id)
                        }
                    }
                    .onAppear {
                        synthAreaSize = geo.size
                    }
                    .onChange(of: geo.size) { new in
                        synthAreaSize = new
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12)) // 讓背景也跟隨圓角
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 420)
            
            // 右：物質列表 (scroll vertical, always kept in order)
            VStack(alignment: .leading) {
                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(gameState.availableList, id: \.self) { id in
                            VStack(spacing: 4) {
                                Image(id) // assets 以 id 命名
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(6)
                                    .shadow(radius: 2)
                                    .onDrag {
                                        // onDrag returns NSItemProvider so we encode elementId
                                        return NSItemProvider(object: id as NSString)
                                    }
                                Text(id)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            .padding(4)
                            // 移除白色背景框
                            // .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                            .onTapGesture {
                                // quick spawn in center of synth area
                                let center = CGPoint(x: synthAreaSize.width/2, y: synthAreaSize.height/2)
                                gameState.spawnItem(elementId: id, at: center)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                // Debug: 快速列出目前載入的元素/配方數（協助確認 elements.json 是否有載入）
                Button {
                    let total = gameState.allElements.count
                    let recipes = gameState.allElements.reduce(0) { $0 + $1.recipes.count }
                    print("[DEBUG] elements loaded = \(total), total recipe entries = \(recipes)")
                    if total == 0 {
                        print("[DEBUG] elements.json 可能沒有正確載入（請檢查 bundle 與檔名）")
                    }
                } label: {
                    //Text("Debug: 檢查 elements 載入")
                        //.font(.caption2)
                        //.foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .frame(width: 50)
            .padding(.horizontal, 6)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Replay") { gameState.resetGame() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("Time: \(gameState.elapsedSeconds)s")
            }
        }
        .onAppear {
            // Start a simple timer for elapsedSeconds (using Task.sleep)
            startTimer()
        }
        .appBackground() // 套用整頁背景（bg）
    }
    
    // MARK: - drag gesture for synthesised items (so user can move them)
    private func dragGesture(for item: SynthesisItem, in geo: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // 只更新位置與拖曳狀態，不做合成判斷
                draggingItemID = item.id
                if let idx = gameState.synthesisItems.firstIndex(where: { $0.id == item.id }) {
                    gameState.synthesisItems[idx].position = value.location
                }
            }
            .onEnded { value in
                // Determine if final location is outside synth area; if so, discard
                let localRect = geo.frame(in: .local)
                let finalPoint = value.location
                if !localRect.contains(finalPoint) {
                    // Remove the item
                    withAnimation(.easeInOut(duration: 0.15)) {
                        gameState.synthesisItems.removeAll { $0.id == item.id }
                    }
                } else {
                    // Clamp position back inside bounds
                    if let idx = gameState.synthesisItems.firstIndex(where: { $0.id == item.id }) {
                        var p = gameState.synthesisItems[idx].position
                        let inset: CGFloat = 0
                        let minX = localRect.minX + inset
                        let maxX = localRect.maxX - inset
                        let minY = localRect.minY + inset
                        let maxY = localRect.maxY - inset
                        p.x = min(max(p.x, minX), maxX)
                        p.y = min(max(p.y, minY), maxY)
                        gameState.synthesisItems[idx].position = p
                        
                        // 放手後再檢查門檻並嘗試合成（唯一觸發點）
                        attemptCombineIfNeeded(for: gameState.synthesisItems[idx])
                    }
                }
                // clear dragging state
                draggingItemID = nil
            }
    }
    
    // 封裝：對 movedItem 檢查其他所有物件，若符合條件則嘗試合成
    private func attemptCombineIfNeeded(for movedItem: SynthesisItem) {
        for other in gameState.synthesisItems {
            if other.id == movedItem.id { continue }
            // Debug：印出當前嘗試的組合與數值
            let ratio = overlapRatio(between: movedItem, and: other)
            let dist = centerDistance(between: movedItem, and: other)
            print("[DEBUG] try pair (\(movedItem.elementId), \(other.elementId)) | overlap=\(String(format: "%.3f", ratio)) dist=\(String(format: "%.1f", dist))")
            
            if canCombine(movedItem: movedItem, with: other) {
                print("[DEBUG] -> pass threshold, will call tryCombine")
                gameState.tryCombine(itemA: movedItem, itemB: other)
                return
            }
        }
    }
    
    // MARK: - 合成條件：重疊比例或中心距離任一達標
    private func canCombine(movedItem: SynthesisItem, with other: SynthesisItem) -> Bool {
        let ratio = overlapRatio(between: movedItem, and: other)
        if ratio >= overlapThreshold { return true }
        
        let d = centerDistance(between: movedItem, and: other)
        if d <= proximityThreshold { return true }
        
        return false
    }

    // Compute overlap ratio between two items based on their frames
    private func overlapRatio(between a: SynthesisItem, and b: SynthesisItem) -> CGFloat {
        let sizeA = CGSize(width: 64 * a.scale, height: 64 * a.scale)
        let sizeB = CGSize(width: 64 * b.scale, height: 64 * b.scale)
        
        // Build rects centered at positions
        let rectA = CGRect(
            x: a.position.x - sizeA.width / 2,
            y: a.position.y - sizeA.height / 2,
            width: sizeA.width,
            height: sizeA.height
        )
        let rectB = CGRect(
            x: b.position.x - sizeB.width / 2,
            y: b.position.y - sizeB.height / 2,
            width: sizeB.width,
            height: sizeB.height
        )
        
        let intersection = rectA.intersection(rectB)
        if intersection.isNull || intersection.isEmpty { return 0 }
        
        let overlapArea = intersection.width * intersection.height
        let areaA = rectA.width * rectA.height
        let areaB = rectB.width * rectB.height
        let smallerArea = min(areaA, areaB)
        if smallerArea <= 0 { return 0 }
        
        return overlapArea / smallerArea
    }
    
    // 中心距離計算
    private func centerDistance(between a: SynthesisItem, and b: SynthesisItem) -> CGFloat {
        let dx = a.position.x - b.position.x
        let dy = a.position.y - b.position.y
        return sqrt(dx*dx + dy*dy)
    }
    
    // Timer
    private func startTimer() {
        // use a Task to tick every second with Task.sleep (works well)
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                gameState.elapsedSeconds += 1
            }
        }
    }
}

struct SynthesisItemView: View {
    var item: SynthesisItem
    var body: some View {
        Image(item.elementId)
            .resizable()
            .frame(width: 64 * item.scale, height: 64 * item.scale)
            .opacity(item.opacity)
            .shadow(radius: 6)
            .transition(.scale .combined(with: .opacity))
    }
}

