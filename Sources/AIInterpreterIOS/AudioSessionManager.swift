import AVFoundation
import Combine

/// 管理 iOS 麦克风权限、音频路由和输入电平。
public final class AudioSessionManager: ObservableObject {
    @Published public private(set) var microphoneAuthorized = false
    @Published public private(set) var statusMessage = "正在检查音频权限和设备"
    @Published public private(set) var routeName = "未连接"
    @Published public private(set) var inputDeviceName = "未选择"
    @Published public private(set) var outputDeviceName = "未选择"
    @Published public private(set) var inputRMS = 0.0

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioEngine: AVAudioEngine?

    /// 请求麦克风权限并刷新当前音频路由。
    @MainActor
    public func refreshPermissionsAndDevices() async {
        microphoneAuthorized = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        refreshRoute()
        statusMessage = microphoneAuthorized ? "设备准备就绪" : "需要麦克风权限"
    }

    /// 开始音频探针，后续由实时网关替换为 PCM 上传管线。
    @MainActor
    public func startProbe() {
        guard microphoneAuthorized else {
            statusMessage = "请先授权麦克风"
            return
        }
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                let value = Self.rms(buffer: buffer)
                DispatchQueue.main.async { self?.inputRMS = value }
            }
            try engine.start()
            audioEngine = engine
            refreshRoute()
            statusMessage = "音频探针已启动，等待翻译网关"
        } catch {
            statusMessage = "无法启动音频：\(error.localizedDescription)"
        }
    }

    /// 停止音频探针并释放系统音频资源。
    @MainActor
    public func stopProbe() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputRMS = 0
        statusMessage = "音频会话已停止"
    }

    /// 刷新当前输入输出路由名称。
    private func refreshRoute() {
        let route = audioSession.currentRoute
        inputDeviceName = route.inputs.first?.portName ?? "未选择"
        outputDeviceName = route.outputs.first?.portName ?? "未选择"
        routeName = "\(inputDeviceName) → \(outputDeviceName)"
    }

    /// 计算音频缓冲区的 RMS，用于判断麦克风是否有有效信号。
    private static func rms(buffer: AVAudioPCMBuffer) -> Double {
        guard let data = buffer.floatChannelData?.pointee else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum = 0.0
        for index in 0..<count {
            let sample = Double(data[index])
            sum += sample * sample
        }
        return (sum / Double(count)).squareRoot()
    }
}
