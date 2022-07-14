//
// MintableProject200Response.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct MintableProject200Response: Codable, JSONEncodable, Hashable {

    /** Whether or not the project can be minted given the machine quota, */
    public var mintable: Bool?
    public var message: String?

    public init(mintable: Bool? = nil, message: String? = nil) {
        self.mintable = mintable
        self.message = message
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mintable
        case message
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(mintable, forKey: .mintable)
        try container.encodeIfPresent(message, forKey: .message)
    }
}

