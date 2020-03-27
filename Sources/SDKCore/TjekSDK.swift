
public final class TjekSDK {

    public struct Config: Decodable {
        public var eventsTracker: EventsTracker.Config?
    }

    public let config: Config
    
    public let eventsTracker: EventsTracker?
    
    public init(config: Config) {
        self.config = config
        
        self.eventsTracker = config.eventsTracker.map({
            EventsTracker(config: $0, uniqueIdStore: .init(
                get: { _ in nil },
                set: { _, _ in }
                )
            )
        })
    }
}


import Foundation

public func foo() throws {
    
    let config = try TjekSDK.Config(
        eventsTracker: EventsTracker.Config(appId: "abc123")
    )
    let sdk = TjekSDK(config: config)
    
    sdk.eventsTracker?.trackEvent(Event(id: Event.Identifier(rawValue: "123"), version: 1, timestamp: Date(), type: 1, payload: [:]))
    
//    Event(id: <#T##Event.Identifier#>, version: <#T##Int#>, timestamp: <#T##Date#>, type: <#T##Int#>, payload: <#T##Event.PayloadType#>)
//    let tracker = try? EventsTracker(config: EventsTracker.Config(appId: "fg"), uniqueIdStore: nil)
    
}
