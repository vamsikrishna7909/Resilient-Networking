//
//  HTTPClient.swift
//  NetworkingPlayground
//
//  Created by Vamsi Krishna Sivakavi on 8/31/25.
//

import Foundation
import CryptoKit

public final class HTTPClient {
    private let session: URLSession
    private let retry: RetryPolicy
    private let logger: HTTPLogger?
    private let deduper = RequestDeduper<Response>()
    
    
    public init(session: URLSession = .shared,
                retry: RetryPolicy? = nil,
                logger: HTTPLogger? = nil) {
        self.session = session
        self.retry = retry ?? ExponentialJitterRetry()  // can be internal here; not in the signature
        self.logger = logger
    }
    
    /// Public entry with in-flight deduping (key from method|url|body SHA-256)
    public func send(_ req: Request, dedupe: Bool = true) async throws -> Response {
        let key = dedupe ? dedupeKey(for: req) : UUID().uuidString
        return try await deduper.run(key: key) { [weak self] in
            guard let self = self else { throw URLError(.cancelled) }
            return try await self._sendWithRetry(req)
        }
    }
    
    private func _sendWithRetry(_ original: Request) async throws -> Response {
        var attempt = 0
        let req = prepared(original)   // prepare ONCE
        while true {
            attempt += 1
            do {
                let resp = try await _sendOnce(req)
                if (200..<300).contains(resp.status) { return resp}
                logger?.log("HTTP \(original.method.rawValue) \(original.url) -> \(resp.status) (attempt \(attempt))")
                // stop retrying on non-transient or past max attempts
                guard let delay = retry.delaySeconds(for: attempt, status: resp.status, error: nil) else {
                    return resp
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1e9))
                try Task.checkCancellation()
            } catch {
                logger?.log("HTTP error \(original.method.rawValue) \(original.url): \(error) (attempt \(attempt))")
                // rethrow if not retrying
                guard let delay = retry.delaySeconds(for: attempt, status: nil, error: error) else {
                    throw error
                }
                try await Task.sleep(nanoseconds: UInt64(delay * 1e9))
                try Task.checkCancellation()
            }
        }
    }
    
    private func prepared(_ req: Request) -> Request {
        var copy = req
        if copy.method == .POST && copy.idempotencyKey == nil {
            copy.idempotencyKey = UUID().uuidString
        }
        return copy
    }
    
    private func _sendOnce(_ req: Request) async throws -> Response {
        var urlReq = URLRequest(url: req.url)
        urlReq.httpMethod = req.method.rawValue
        urlReq.httpBody = req.body
        req.headers.forEach { urlReq.setValue($0.value, forHTTPHeaderField: $0.key)}
        if let key = req.idempotencyKey {
            urlReq.setValue(key, forHTTPHeaderField: "Idempotency-Key")
        }
        let (data, urlResp) = try await session.data(for: urlReq)
        let http = urlResp as? HTTPURLResponse
        return Response(status: http?.statusCode ?? -1, headers: http?.allHeaderFields ?? [:], data: data)
    }
    
    //Stable dedupe key via SHA-256 of "METHOD␟URL␟len␟body" instead of Hasher() because it is emphemeral
    private func dedupeKey(for req: Request) -> String {
        // **Stable SHA-256**; no process-random Hasher
        var sha = SHA256()

        func update(_ s: String) {
            sha.update(data: Data(s.utf8))
        }

        update(req.method.rawValue)
        update("|")
        update(req.url.absoluteString)

        if let body = req.body {
            update("|")
            // include a fixed-width length prefix to disambiguate boundaries
            var len = UInt64(body.count).bigEndian
            withUnsafeBytes(of: &len) { rawBuf in
                sha.update(data: Data(rawBuf))
            }
            sha.update(data: body)
        }

        let digest = sha.finalize()
        // hex string
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
