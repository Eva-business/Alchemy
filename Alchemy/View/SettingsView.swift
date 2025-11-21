import SwiftUI

struct SettingsView: View {
    @Environment(GameState.self) var gameState
    @State private var showTutorial = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Light green background
                Color.green.opacity(0.15)
                    .ignoresSafeArea()
                
                Form {
                    Toggle("音效", isOn: Binding(get: { gameState.soundOn }, set: { gameState.soundOn = $0 }))
                    Toggle("背景音樂", isOn: Binding(
                        get: { gameState.musicOn },
                        set: { newValue in
                            gameState.musicOn = newValue
                            if newValue {
                                gameState.startBackgroundMusic()
                            } else {
                                gameState.stopBackgroundMusic()
                            }
                        }
                    ))
                    Button("重玩（Replay）") { gameState.resetGame() }
                    Button("教學") { showTutorial.toggle() }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .onAppear {
                // 若使用者開啟了背景音樂且尚未在播，啟動它
                if gameState.musicOn, gameState.bgAudioPlayer == nil {
                    gameState.startBackgroundMusic()
                }
            }
            .sheet(isPresented: $showTutorial) {
                TutorialView()
            }
        }
    }
}

struct TutorialView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("遊戲教學").font(.title)
            Text("1. 從右側拖動物質到左側合成區，或點擊物質將其放在中間。")
            Text("2. 當兩個物質重疊（或靠近）時，會自動嘗試合成。")
            Text("3. 合成成功會解鎖新物質，它將出現在物質列表中。")
            Spacer()
        }
        .padding()
    }
}
