import SwiftUI

/// iOS 实时翻译 App 的 SwiftUI 入口视图。
public struct AIInterpreterAppView: View {
    /// 音频会话管理器，负责权限、设备路由和电平状态。
    @StateObject private var audioSession = AudioSessionManager()

    public init() {}

    public var body: some View {
        NavigationStack {
            ContentView(audioSession: audioSession)
                .navigationTitle("实时双向翻译")
        }
    }
}
