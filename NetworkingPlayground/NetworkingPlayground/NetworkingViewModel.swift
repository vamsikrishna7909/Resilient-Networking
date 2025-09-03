//
//  NetworkingViewModel.swift
//  NetworkingPlayground
//
//  Created by Vamsi Krishna Sivakavi on 9/1/25.
//

import Foundation

@MainActor
final class NetworkingViewModel: ObservableObject {
    @Published var log: String = ""
    private let logger: ConsoleLogger
    private let client: HTTPClient
    
    init(log: String, logger: ConsoleLogger, client: HTTPClient) {
        self.log = log
        self.logger = logger
        self.client = HTTPClient(logger: logger)
    }
    
    struct Todo: Decodable {
        let id: Int
        let title: String
        let completed: Bool
    }
    
    func fetchDeduped() {
        append("Get pressed -> fire 3 identical requests quickly; server hit should be 1")
        Task {
            let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
            let req = Request(method: .GET, url: url)
            async let a: Response = client.send(req)
            async let b: Response = client.send(req)
            async let c: Response = client.send(req)
            
            do {
                let (r1, r2, r3) = try await (a, b, c)
                let todo: Todo = try JSON.decode(r1.data)
                append("Deduped OK: \(todo.title)\nStatuses: [\(r1.status), \(r2.status), \(r3.status)]")
            } catch {
                append("Error: \(error)")
            }
        }
    }
    
    func createTodoWithRetry() {
        append("POST pressed -> will retry on transient errors (Idempotency-Key included)")
        
        Task {
            let url = URL(string: "https://jsonplaceholder.typicode.com/todos")!
            let bodyDict: [String: AnyEncodable] = [
                "title": AnyEncodable("demo"),
                "completed": AnyEncodable(false),
                "userId": AnyEncodable(1)
            ]
            let body = try? JSON.encode(bodyDict)
            let req = Request(method: .POST, url: url, headers:  ["Content-Type":"application/json"], body: body)
            
            do {
                let resp = try await client.send(req, dedupe: false) //POSTs usually not deduped
                append("POST status: \(resp.status), bytes: \(resp.data.count)")
            } catch {
                append("POST failed: \(error)")
            }
        }
    }
    
    private func append(_ s: String) {
        log.append((log.isEmpty ? "" : "\n") + "🧪 " + s)
        logger.log(s)
    }
}
