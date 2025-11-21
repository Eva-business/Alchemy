import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState() // 保持 instance 的地方
    var body: some View {
        TabView {
            MainGameView()
                .tabItem { Label("Game", systemImage: "flame.fill") }
            EncyclopediaView()
                .tabItem { Label("Encyclopedia", systemImage: "book.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(gameState) // <- 注入 Observation 型別到 Environment
    }
}

#Preview {
    ContentView()
}
