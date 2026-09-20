# AI Interpreter iOS

## 当前状态

这是 iOS 原生工程的第一阶段 SwiftUI 源码骨架，包含：

- 麦克风权限请求；
- AVAudioSession 音频路由显示；
- 蓝牙输入输出路由状态；
- 麦克风 RMS 电平探针；
- 四栏字幕界面占位；
- 启动和停止音频会话。

当前 Windows 环境无法运行 Xcode 和 iOS Simulator，因此未在本机完成 Xcode 编译和真机验收。接入实时网关前，必须在 macOS/Xcode 中创建 App target、配置签名，并完成真实 iPhone/蓝牙耳机验收。

## 使用方式

1. 在 macOS 上用 Xcode 创建一个 iOS App target。
2. 将 `Sources/AIInterpreterIOS` 中的 Swift 文件加入 target。
3. 配置 `NSMicrophoneUsageDescription`。
4. 用真机验证麦克风、蓝牙路由、锁屏和来电中断。
5. 再接入统一 WebSocket 翻译网关，不在 App 内保存供应商长期 API Key。
