//
//  NetworkingCore.swift
//  NetworkingPlayground
//
//  Created by Vamsi Krishna Sivakavi on 8/30/25.
//

import Foundation

public enum HTTPMethod: String { case GET, POST, PUT, PATCH, DELETE }


public struct Request {
    public var method: HTTPMethod
    public var url: URL
    public var headers: [String: String] = [:]
    public var body: Data? = nil
    public var idempotencyKey: String? = nil //set automatically for POST if missing
    
    public init(method: HTTPMethod, url: URL, headers: [String: String] = [:], body: Data? = nil, idempotencyKey: String? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.idempotencyKey = idempotencyKey
    }
}

public struct Response {
    public let status: Int
    public let headers: [AnyHashable: Any]
    public let data: Data
}

public protocol HTTPLogger { func log(_ message: String) }

public struct ConsoleLogger: HTTPLogger {
//    public init() {}
    public func log(_ message: String) { print("🌐 \(message)" )}
}


public protocol RetryPolicy {
    ///Return delay seconds for attempt index(1-based), Return nil to stop retrying.
    func delaySeconds(for attempt:Int, status: Int?, error: Error?) -> Double?
}

/// Exponential backoff with full jitter. Retry 5xx/429/408 or network errors.
public struct ExponentialJitterRetry: RetryPolicy {
    public let maxAttempts: Int
    public let base: Double
    public let multiplier: Double
    
    public init(maxAttempts: Int = 3, base: Double = 5.0, multiplier: Double = 2.0) {
        self.maxAttempts = maxAttempts
        self.base = base
        self.multiplier = multiplier
    }
    
    public func delaySeconds(for attempt: Int, status: Int?, error: Error?) -> Double? {
        guard attempt < maxAttempts else { return nil }
    
        let transient = (status.map { $0 == 400 || $0 == 429 || (500..<600).contains($0) } ?? false) || (error != nil)
        guard transient else { return nil }
        let cap = base * pow(multiplier, Double(attempt - 1))
        return Double.random(in: 0...cap) // full jitter. A deviation from true period. That avoids the “thundering herd problem” where many clients retry at the exact same time.
    }
}
