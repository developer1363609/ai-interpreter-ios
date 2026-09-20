import SwiftUI

/// iOS 主界面：结构与 Android 端保持一致，只使用 iOS 原生控件外观。
public struct ContentView: View {
    @ObservedObject var audioSession: AudioSessionManager
    @State private var isRunning = false
    @State private var languageDirection = "中文 → 英文"
    @State private var outboundVoice = "偏男声 1 Cedar"
    @State private var inboundVoice = "偏女声 1 Marin"

    public init(audioSession: AudioSessionManager) {
        self.audioSession = audioSession
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                topBar
                fieldLabel("语言方向")
                Picker("语言方向", selection: $languageDirection) {
                    Text("中文 → 英文").tag("中文 → 英文")
                    Text("英文 → 中文").tag("英文 → 中文")
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))

                fieldLabel("发给对方的声音")
                voicePicker(selection: $outboundVoice)
                fieldLabel("我听到的声音")
                voicePicker(selection: $inboundVoice)

                fieldLabel("输入设备")
                deviceRow(audioSession.inputDeviceName)
                fieldLabel("输出设备")
                deviceRow(audioSession.outputDeviceName)

                captionPanel(title: "我说的原文", text: "等待输入语音", color: .blue)
                captionPanel(title: "给对方的译文", text: "等待翻译", color: .green)
                captionPanel(title: "对方原文", text: "等待对方语音", color: .gray)
                captionPanel(title: "给我的译文", text: "等待翻译", color: .orange)

                Button(isRunning ? "停止音频会话" : "检查并开始翻译") {
                    isRunning.toggle()
                    if isRunning { audioSession.startProbe() }
                    else { audioSession.stopProbe() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.09, green: 0.21, blue: 0.36))
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 11))

                Text(audioSession.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.93, green: 0.95, blue: 0.97))
        .task { await audioSession.refreshPermissionsAndDevices() }
    }

    /// 顶部导航和准备状态，保持与 Android 草图相同的位置和层级。
    private var topBar: some View {
        HStack {
            Text("实时翻译")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Text("准备")
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color(red: 0.09, green: 0.21, blue: 0.36), in: RoundedRectangle(cornerRadius: 11))
    }

    /// 显示字段标签，统一两端的信息层级。
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
    }

    /// 显示一个可替换的输入或输出设备行。
    private func deviceRow(_ name: String) -> some View {
        HStack {
            Text(name.isEmpty ? "选择设备" : name)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    /// 声音选择器：三种偏男声和三种偏女声，会在会话开始前锁定。
    private func voicePicker(selection: Binding<String>) -> some View {
        Picker("声音", selection: selection) {
            Text("偏男声 1 Cedar").tag("偏男声 1 Cedar")
            Text("偏男声 2 Ash").tag("偏男声 2 Ash")
            Text("偏男声 3 Echo").tag("偏男声 3 Echo")
            Text("偏女声 1 Marin").tag("偏女声 1 Marin")
            Text("偏女声 2 Coral").tag("偏女声 2 Coral")
            Text("偏女声 3 Shimmer").tag("偏女声 3 Shimmer")
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    /// 四栏字幕卡片，语义与 Android 和 Web H5 完全一致。
    private func captionPanel(title: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(text).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(minHeight: 42, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
    }
}
