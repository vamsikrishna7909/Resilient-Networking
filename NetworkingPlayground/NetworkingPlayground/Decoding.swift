//
//  Decoding.swift
//  NetworkingPlayground
//
//  Created by Vamsi Krishna Sivakavi on 9/1/25.
//

import Foundation

public enum JSON {
    public static func encode<T: Encodable>(_ value: T) throws -> Data {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        return try enc.encode(value)
    }
    
    public static func decode<T: Decodable>(_ data: Data) throws -> T {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return try dec.decode(T.self, from: data)
    }
}

// Helper for heterogenous dictionaries
public struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    public init<T: Encodable>(_ wrapped: T) { self.encodeFunc = wrapped.encode }
    public func encode(to encoder: any Encoder) throws {
        try encodeFunc(encoder)
    }
}

//Normally, Swift won’t let you do [String: Encodable], because it doesn’t know which concrete encode to call later. AnyEncodable solves this by locking in the concrete encode function at init time, and replaying it later via encodeFunc.
