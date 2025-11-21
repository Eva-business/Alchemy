import SwiftUI

struct EncyclopediaView: View {
    @Environment(GameState.self) var gameState
    @State private var query: String = ""
    
    private var undiscoveredCount: Int {
        max(gameState.allElements.count - gameState.unlocked.count, 0)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Light green background
                Color.green.opacity(0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜尋
                    HStack {
                        TextField("search", text: $query)
                            .textFieldStyle(.roundedBorder)
                        if !query.isEmpty {
                            Button {
                                query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 8)
                    
                    // 列表（只顯示已解鎖）
                    List {
                        ForEach(filteredUnlockedElements(), id: \.id) { e in
                            NavigationLink(destination: ElementDetailView(element: e).appBackground()) {
                                HStack(spacing: 12) {
                                    Image(e.id)
                                        .resizable()
                                        .frame(width: 44, height: 44)
                                        .cornerRadius(6)
                                        .shadow(radius: 2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(e.name)
                                            .font(.headline)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    // Hide list background so green shows through
                    .scrollContentBackground(.hidden)
                    
                    // 底部：未發現總數（加材質讓文字清楚）
                    VStack {
                        Text("尚未發現的物質：\(undiscoveredCount) 種")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("物質百科")
        }
        // Keep your unified background modifier if desired; the ZStack already provides green.
        // .appBackground()
    }
    
    // 僅顯示已解鎖；搜尋時仍限制在已解鎖集合內
    private func filteredUnlockedElements() -> [Element] {
        let unlockedSet = gameState.unlocked
        let base = gameState.allElements.filter { unlockedSet.contains($0.id) }
        guard !query.isEmpty else { return base }
        let q = query.lowercased()
        return base.filter { $0.id.lowercased().contains(q) || $0.name.lowercased().contains(q) }
    }
}

private struct ElementDetailView: View {
    @Environment(GameState.self) var gameState
    let element: Element
    
    // 將每條配方標記是否已解鎖（兩材料都解鎖）
    private var recipeRows: [(ingredients: [String], isUnlocked: Bool)] {
        element.recipes.map { r in
            let ok = r.count == 2 && gameState.unlocked.contains(r[0]) && gameState.unlocked.contains(r[1])
            return (r, ok)
        }
    }
    
    private var unlockedCount: Int {
        recipeRows.filter { $0.isUnlocked }.count
    }
    private var lockedCount: Int {
        max(element.recipes.count - unlockedCount, 0)
    }
    
    var body: some View {
        // 整體下移一點，避開返回按鈕區塊
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(element.id)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(element.name)
                            .font(.title2).bold()
                        // 已移除小標題（原本顯示 element.id）
                    }
                    Spacer()
                }
                
                // 配方區塊（有幾個配方就顯示幾列，左右分散對齊且佔滿寬度）
                VStack(alignment: .leading, spacing: 8) {
                    Text("合成配方")
                        .font(.headline)
                    
                    if recipeRows.isEmpty {
                        Text("此元素沒有定義配方")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(recipeRows.enumerated()), id: \.offset) { _, row in
                                HStack {
                                    // 左材料
                                    ingredientTile(for: row.ingredients.first, showReal: row.isUnlocked)
                                        .frame(maxWidth: .infinity)
                                    
                                    Text("+")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    
                                    // 右材料
                                    ingredientTile(for: row.ingredients.dropFirst().first, showReal: row.isUnlocked)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                            }
                        }
                        
                        // 底部顯示剩餘幾種合成方法
                        Text("剩餘 \(lockedCount) 種合成方法")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
            .padding()
        }
        .padding(.top, 56) // 讓內容整體往下移，避開返回按鈕/導航列區域（可依視覺調整 44~64）
        // 保留返回按鈕，但隱藏導航列的模糊背景
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        // Keep existing background if you want; the parent page uses green now.
        .appBackground()
    }
    
    // 單一材料的方塊（圖片＋名稱，置中）
    @ViewBuilder
    private func ingredientTile(for id: String?, showReal: Bool) -> some View {
        if showReal, let id, let el = gameState.allElements.first(where: { $0.id == id }) {
            VStack(spacing: 6) {
                Image(el.id)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .cornerRadius(8)
                    .shadow(radius: 1)
                Text(el.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
                    .background(.thinMaterial, in: Capsule())
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        } else {
            VStack(spacing: 6) {
                Image("bg") // 這裡仍要問號，保留 placeholder
                    .resizable()
                    .frame(width: 48, height: 20)
                    .cornerRadius(8)
                    .opacity(0) // 佔位別用 bg，改回問號
                // 用問號占位
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
    }
}
