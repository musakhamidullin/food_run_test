import ActivityKit
import Foundation

struct StatusAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var statusName: String
        var stepNumber: Int
        var icon: String
        var guestNumber: String
    }

    var address: String
}
