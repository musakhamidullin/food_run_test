import Flutter

class PushBridge {
    static let shared = PushBridge()
    private var channel: FlutterMethodChannel?

    func setChannel(_ channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func sendPushPayload(_ userInfo: [AnyHashable: Any], source: String) {
        var payload: [String: Any] = ["source": source]

        if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            payload["data"] = jsonString
        }

        channel?.invokeMethod("onNativePush", arguments: payload)
    }
}
