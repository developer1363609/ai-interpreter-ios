import SwiftUI

/// iOS 首期翻译主界面：设备选择、状态和四栏字幕。
public struct ContentView: View {
    @ObservedObject var audioSession: AudioSessionManager
    @State private var isRunning = false

    public init(audioSession: AudioSessionManager) {
        self.audioSession = audioSession
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusSection
                deviceSection
                captionSection
                actionSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .task {
            await audioSession.refreshPermissionsAndDevices()
        }
    }

    /// 显示当前权限、蓝牙路由和翻译会话状态。
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(audioSession.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label(audioSession.microphoneAuthorized ? "麦克风已授权" : "需要麦克风权限", systemImage: "mic")
                Spacer()
                Label(audioSession.routeName, systemImage: "wave.3.right")
            }
            .font(.caption)
        }
        .padding()
        .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }

    /// 显示系统当前可用的音频输入和输出设备。
    private var deviceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("音频设备").font(.headline)
            Text("输入：\(audioSession.inputDeviceName)")
            Text("输出：\(audioSession.outputDeviceName)")
                .foregroundStyle(.secondary)
            Text(String(format: "当前音量 RMS %.3f", audioSession.inputRMS))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    /// 显示四栏实时字幕，保持与 Web 和桌面版一致的数据语义。
    private var captionSection: some View {
        VStack(spacing: 10) {
            CaptionPanel(title: "我说的原文", text: "等待输入语音", color: .blue)
            CaptionPanel(title: "给对方的译文", text: "等待翻译", color: .green)
            CaptionPanel(title: "对方原文", text: "等待对方语音", color: .gray)
            CaptionPanel(title: "给我的译文", text: "等待翻译", color: .orange)
        }
    }

    /// 提供启动和停止音频会话的单一主操作。
    private var actionSection: some View {
        Button(isRunning ? "停止音频会话" : "检查并开始翻译") {
            isRunning.toggle()
            if isRunning {
                audioSession.startProbe()
            } else {
                audioSession.stopProbe()
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }
}

private struct CaptionPanel: View {
    let title: String
    let text: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(text).font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}
