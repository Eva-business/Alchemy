! 此readme由AI生成

Alchemy

一款以組合元素解鎖新事物為核心的休閒解謎遊戲。玩家從基礎元素開始，透過拖曳/點擊組合，探索出越來越多的複合元素，逐步完成圖鑑與挑戰。

特色
• 直覺操作：點擊或拖曳兩個元素進行合成
• 探索樂趣：從少量基礎元素出發，逐步解鎖上百種新元素
• 進度保存：自動保存已解鎖元素與圖鑑進度
• 清爽 UI：以 SwiftUI 打造，支援深色模式
• 可擴充：元素資料與配方可外部化，方便後續新增關卡或主題

平台與技術
• 平台：iOS（可擴充至 iPadOS / macOS Catalyst）
• 語言與框架：Swift、SwiftUI、Swift Concurrency（如有）
• 專案型式：SwiftUI App（@main AlchemyApp -> ContentView）
• 套件管理：Swift Package Manager（如有第三方套件）
• 最低系統版本：請填寫 iOS 版本（例如 iOS 16+）
• Xcode 版本：請填寫（例如 Xcode 16+）

安裝與建置
• 需求
   • Xcode：16 或以上（依你的實際版本調整）
   • iOS：16 或以上（依你的實際目標調整）
• 取得原始碼
   • git clone https://github.com/your/repo.git
   • 使用 Xcode 開啟專案
• 依賴套件
   • 若使用 SPM：Xcode > File > Add Packages… 加入所需套件
• 執行
   • 選擇 Alchemy target，按下 Cmd+R 在模擬器或實機上運行

遊戲玩法
• 目標：透過組合元素來解鎖所有可發現的元素，完成圖鑑
• 操作方式（依你實作擇一或多選）
   • 點擊兩個元素進行合成
   • 拖曳一個元素到另一個元素上進行合成
• 提示與回饋
   • 若配方正確：產生新元素並加入圖鑑
   • 若無效組合：給予提示或微回饋
• 進度
   • 自動保存已解鎖元素
   • 可在設定中重置進度（如有）

專案結構（建議）
• AlchemyApp.swift􀰓：App 入口（@main），載入 ContentView
• ContentView.swift：主要 UI 與遊戲場景容器
• Models/
   • Element.swift：元素資料模型（id、名稱、分類、圖示等）
   • Recipe.swift：配方模型（輸入元素組合 -> 輸出元素）
• ViewModels/
   • GameViewModel.swift：遊戲邏輯、合成判斷、狀態管理（已解鎖元素、當前選取等）
• Views/
   • ElementGridView.swift：元素清單/圖鑑展示
   • WorkbenchView.swift：合成工作台（拖曳/點擊區域）
   • ElementDetailView.swift：元素詳情（描述、來源、配方提示）
• Services/
   • PersistenceService.swift：進度儲存（UserDefaults/JSON/Keychain/CoreData 擇一）
   • RecipeProvider.swift：載入配方（本地 JSON 或遠端）
• Resources/
   • Assets.xcassets：圖示與圖片
   • Data/recipes.json：元素與配方資料（如採資料驅動）
• Tests/
   • 單元測試：Recipe 合成邏輯、Persistence 正確性
   • UI 測試：基本流程（解鎖、搜索、重置）

資料與儲存（示例）
• 已解鎖元素以 ID 陣列保存（如使用 UserDefaults）
• 配方以 JSON 檔案管理，利於版本控制與調整
• 可考慮版本遷移（資料結構更新時的兼容）

無障礙與在地化
• Dynamic Type：支援字體縮放
• VoiceOver：元素名稱與合成結果可被讀出
• 語系：預設 zh-Hant，可擴充 en 等

測試
• 單元測試（Swift Testing 或 XCTest）
   • 測 Recipe 合成：輸入元素 A+B 應產生 C
   • 測進度儲存：新增/重置後狀態正確
• UI 測試
   • 基本流程：選擇兩元素 -> 合成 -> 新元素顯示於圖鑑
• 執行方式
   • Xcode：Product > Test 或 Cmd+U
   • 指令列：xcodebuild test -scheme "Alchemy" -destination 'platform=iOS Simulator,name=iPhone 15'

效能與品質
• Instruments：監測記憶體與主執行緒阻塞
• Lint/格式化：SwiftFormat/SwiftLint（如使用）
• 日誌：OSLog 分層記錄（如需要）

路線圖（可選）
• 新增主題包：神話/科技/自然等配方集
• 難度模式：限制步數或時間
• 線上排行榜或成就系統
• iCloud 同步進度
• 多平台支援：iPadOS、macOS（Catalyst）

常見問題
• 看不到新元素？
   • 確認組合是否有效，或查看提示
• 進度遺失？
   • 檢查是否移除 App 或重置設定；建議加入 iCloud/備份（未來規劃）
• 當機或卡頓？
   • 提供裝置型號、iOS 版本與重現步驟回報 Issue
