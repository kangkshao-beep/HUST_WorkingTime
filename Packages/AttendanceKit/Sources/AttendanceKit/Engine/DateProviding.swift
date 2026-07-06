import Foundation

public protocol DateProviding: Sendable {
    var now: Date { get }
}

public struct SystemDateProvider: DateProviding {
    public init() {}
    public var now: Date { Date() }
}

public struct FixedDateProvider: DateProviding {
    public let now: Date
    public init(now: Date) {
        self.now = now
    }
}
