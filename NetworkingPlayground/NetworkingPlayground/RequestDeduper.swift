//
//  RequestDeduper.swift
//  NetworkingPlayground
//
//  Created by Vamsi Krishna Sivakavi on 8/30/25.
//

actor RequestDeduper<T> {
    private var tasks: [String: Task<T, Error>] = [:]
    
    func run(key: String, _ make: @escaping () async throws -> T) async throws -> T {
        if let existing = tasks[key] { return try await existing.value }
        let t = Task { try await make() }
        tasks[key] = t
        defer { tasks[key] = nil }
        return try await t.value
    }
}
