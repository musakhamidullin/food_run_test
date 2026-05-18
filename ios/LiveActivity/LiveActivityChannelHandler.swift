import Flutter
import Foundation

final class LiveActivityChannelHandler {

    private let channel: FlutterMethodChannel
    private var lastMethodCalled: String?

    init(binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "live_activity",
            binaryMessenger: binaryMessenger
        )
        channel.setMethodCallHandler(handle)
    }

    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            handleStart(call: call, result: result)
            lastMethodCalled = call.method
        case "update":
            handleUpdate(call: call, result: result)
            lastMethodCalled = call.method
        case "end":
            handleEnd(call: call, result: result)
            lastMethodCalled = call.method
        case "getLastMethod":
            result(lastMethodCalled)
        default:
            result(nil)
        }
    }

    private func handleStart(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let address    = args["address"]     as? String,
              let statusName = args["statusName"]  as? String,
              let guestNumber = args["guestNumber"] as? String,
              let stepNumber = args["stepNumber"]  as? Int,
              let icon       = args["icon"]        as? String,
              let orderId    = args["orderId"]     as? Int
        else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid start args", details: nil))
            return
        }

        Task {
            do {
                try await LiveActivityManager.shared.start(
                    address: address,
                    statusName: statusName,
                    guestNumber: guestNumber,
                    stepNumber: stepNumber,
                    icon: icon,
                    orderId: orderId
                )
                result(nil)
            } catch {
                result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }

    private func handleUpdate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let statusName  = args["statusName"]  as? String,
              let stepNumber  = args["stepNumber"]  as? Int,
              let icon        = args["icon"]        as? String,
              let guestNumber = args["guestNumber"] as? String
        else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid update args", details: nil))
            return
        }

        Task {
            await LiveActivityManager.shared.update(
                statusName: statusName,
                stepNumber: stepNumber,
                icon: icon,
                guestNumber: guestNumber
            )
            result(nil)
        }
    }

    private func handleEnd(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let statusName  = args["statusName"]  as? String,
              let stepNumber  = args["stepNumber"]  as? Int,
              let icon        = args["icon"]        as? String,
              let guestNumber = args["guestNumber"] as? String
        else {
            result(FlutterError(code: "BAD_ARGS", message: "Invalid end args", details: nil))
            return
        }

        Task {
            await LiveActivityManager.shared.end(
                statusName: statusName,
                stepNumber: stepNumber,
                icon: icon,
                guestNumber: guestNumber
            )
            result(nil)
        }
    }
}
