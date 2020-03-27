//
//  ┌────┬─┐         ┌─────┐
//  │  ──┤ └─┬───┬───┤  ┌──┼─┬─┬───┐
//  ├──  │ ╷ │ · │ · │  ╵  │ ╵ │ ╷ │
//  └────┴─┴─┴───┤ ┌─┴─────┴───┴─┴─┘
//               └─┘
//
//  Copyright (c) 2018 ShopGun. All rights reserved.

import Foundation

public final class EventsTracker {
    
    public typealias AppIdentifier = String
    
    public struct Context {
        /**
         The location information of the app's user. Once set, this will be sent with all future tracked events.
         - A geohash of the location (this will have an accuracy no-greater than ±20km)
         - The timestamp of when that location info was collected.
         
         It is up to you to collect this info from the user. See the `updateLocation(latitude:longitude:timestamp:)` method.
         */
        public private(set) var location: (geohash: String, timestamp: Date)? = nil
        
        /**
         Updates the `location` property, using a lat/lng/timestamp to generate the geohash (to an accuracy of ±20km). This geohash will be included in all _future_ tracked events, until `clearLocation()` is called.
         - Note: It is up to the user of the SDK to decide how this location information is collected. We recommend, however, that only GPS-sourced location data is used.
         - parameter latitude: The latitide to use when generating the `location`'s geohash.
         - parameter longitude: The longitude to use when generating the `location`'s geohash.
         - parameter timestamp: The date that the lat/lng pair was generated (eg. when the user was discovered to be at that location)
         */
        public mutating func updateLocation(latitude: Double, longitude: Double, timestamp: Date) {
            let hash = Geohash.encode(latitude: latitude, longitude: longitude, length: 4) // ±20km
            self.location = (hash, timestamp)
        }
        
        /**
         After this is called, the `location` geohash/timestamp will be set to `nil` and no longer sent with future tracked events.
         */
        public mutating func clearLocation() {
            self.location = nil
        }
    }
    
    public struct Config {
        
        public var appId: AppIdentifier
        public var baseURL: URL
        public var dispatchInterval: TimeInterval
        public var dispatchLimit: Int
        public var enabled: Bool
        
        public init(
            appId: AppIdentifier,
            baseURL: URL = URL(string: "https://wolf-api.tjek.com")!,
            dispatchInterval: TimeInterval = 120.0,
            dispatchLimit: Int = 100,
            enabled: Bool = true
        ) throws {
            
            guard !appId.isEmpty else {
                throw(EventsTracker.TrackerError.appIdEmpty)
            }
            
            self.appId = appId
            self.baseURL = baseURL
            self.dispatchInterval = dispatchInterval
            self.dispatchLimit = dispatchLimit
            self.enabled = enabled
        }
    }
    
    public struct UniqueIdStore {
        let get: (_ key: String) -> String?
        let set: (_ key: String, _ value: String?) -> Void
    }
    
    fileprivate enum TrackerError: Error {
        case appIdEmpty
    }
    
    // MARK: Public vars
    
    public let config: Config
    
    /// The `Context` that will be attached to all future events (at the moment of tracking).
    /// Modifying the context will only change events that are tracked in the future
    public var context: Context = Context()
    
    // MARK: Private vars
    
    var viewTokenizer: UniqueViewTokenizer
    
    var uniqueIdStore: UniqueIdStore?
    
    let pool: EventsPool
    
    // MARK: Public funcs
    
    public init(config: Config, uniqueIdStore: UniqueIdStore?) {
        self.config = config
        self.uniqueIdStore = uniqueIdStore
        self.viewTokenizer = UniqueViewTokenizer.load(from: uniqueIdStore)
        
        let eventsShipper = EventsShipper(
            baseURL: config.baseURL,
            dryRun: config.enabled == false,
            appContext: .init(id: config.appId)
        )
        
        let eventsCache = EventsCache<ShippableEvent>(fileName: "com.shopgun.ios.sdk.events_pool.disk_cache.v2.plist")
        
        self.pool = EventsPool(dispatchInterval: config.dispatchInterval,
                               dispatchLimit: config.dispatchLimit,
                               shippingHandler: eventsShipper.ship,
                               cache: eventsCache)
    }
    
    /// Add an event to the 'to-be-sent' pool.
    public func trackEvent(_ event: Event) {
        
        // TODO: Do on shared queue?
        
        // Mark the event with the tracker's context & appId
        let eventToTrack = event
            .addingAppIdentifier(self.config.appId)
            .addingContext(self.context)
        
        // push the event to the cached pool
        guard let shippableEvent = ShippableEvent(event: eventToTrack) else { return }
        
        self.pool.push(event: shippableEvent)
        
        DidTrackEventNotification(event: eventToTrack).post(for: self)
        
        //        Logger.log("📩 Event Tracked: \(shippableEvent)", level: .debug, source: .EventsTracker)
    }
    
    /// This will generate a new tokenizer with a new salt. Calling this will mean that any ViewToken sent with future events will not be connected to any historically shipped events.
    public func resetViewTokenizerSalt() {
        self.viewTokenizer = UniqueViewTokenizer.reload(from: uniqueIdStore)
    }
    
    /// Tries to send all the remaining events.
    public func sendPendingEvents() {
        pool.flushPending()
    }
}

// MARK: - Tracking Notifications

extension EventsTracker {
    
    public struct DidTrackEventNotification {
        
        public static let name = Notification.Name(rawValue: "ShopGunSDK.EventsTracker.eventTracked")
        
        public let event: Event
        
        public init(event: Event) {
            self.event = event
        }
        
        public init?(notification: Notification) {
            guard notification.name == DidTrackEventNotification.name,
                let event = notification.userInfo?["trackedEvent"] as? Event
                else {
                    return nil
            }
            
            self.init(event: event)
        }
        
        fileprivate func post(for tracker: EventsTracker, on notifCenter: NotificationCenter = .default) {
            notifCenter.post(
                name: DidTrackEventNotification.name,
                object: tracker,
                userInfo: ["trackedEvent": self.event as Any]
            )
        }
    }
}

// MARK: -

extension EventsTracker.Config: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case appId
        case baseURL
        case dispatchInterval
        case dispatchLimit
        case enabled
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let appId = try container.decode(String.self, forKey: .appId)
        
        try self.init(appId: appId)
        
        if let baseURLStr = try? container.decode(String.self, forKey: .baseURL), let baseURL = URL(string: baseURLStr) {
            self.baseURL = baseURL
        }
        
        if let dispatchInterval = try? container.decode(TimeInterval.self, forKey: .dispatchInterval) {
            self.dispatchInterval = dispatchInterval
        }
        
        if let dispatchLimit = try? container.decode(Int.self, forKey: .dispatchLimit) {
            self.dispatchLimit = dispatchLimit
        }
        
        if let enabled = try? container.decode(Bool.self, forKey: .enabled) {
            self.enabled = enabled
        }
    }
}
