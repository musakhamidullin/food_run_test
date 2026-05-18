import ActivityKit
import Foundation

final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<StatusAttributes>?

    func start(
        address: String,
        statusName: String,
        guestNumber: String,
        stepNumber: Int,
        icon: String,
        orderId: Int
    ) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = StatusAttributes.ContentState(
            statusName: statusName,
            stepNumber: stepNumber,
            icon: icon,
            guestNumber: guestNumber
        )

        let attributes = StatusAttributes(address: address)

        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())

        do {
            currentActivity = try Activity<StatusAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: staleDate),
                pushType: .token
//                pushType: nil
            )

            Task {
                for await tokenData in currentActivity!.pushTokenUpdates {
                    let token = tokenData.map { String(format: "%02x", $0) }.joined()

//                    пока закомментим, чтобы в прод не ушло
                    await sendLiveActivityToken(orderId: orderId, token: token)
                }
            }

            print("Started Live Activity:", currentActivity?.id ?? "nil")
        } catch {
            print("Live Activity start error:", error)
        }
    }

    func update(
        statusName: String,
        stepNumber: Int,
        icon: String,
        guestNumber: String
    ) async {
        let state = StatusAttributes.ContentState(
            statusName: statusName,
            stepNumber: stepNumber,
            icon: icon,
            guestNumber: guestNumber
        )
        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())

        await currentActivity?.update(
            ActivityContent(state: state, staleDate: staleDate)
        )
    }

    func end(
        statusName: String,
        stepNumber: Int,
        icon: String,
        guestNumber: String
    ) async {
        let finalState = StatusAttributes.ContentState(
            statusName: statusName,
            stepNumber: stepNumber,
            icon: icon,
            guestNumber: guestNumber
        )
        let staleDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date())

        await currentActivity?.end(
            ActivityContent(state: finalState, staleDate: staleDate),
            dismissalPolicy: .immediate
        )
        currentActivity = nil
    }

    private func sendLiveActivityToken(orderId: Int, token: String) async {
        guard let url = URL(string: "https://api.foodrun.ru/api/projects/main/orders/\(orderId)/live-activity/") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["push_token": token]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                print("Live Activity token sent, status:", http.statusCode)
            }
            print("Response:", String(data: data, encoding: .utf8) ?? "")
        } catch {
            print("sendLiveActivityToken failed:", error)
        }
    }
}
