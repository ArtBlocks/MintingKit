//
// CreateMintingRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct CreateMintingRequest: Codable, JSONEncodable, Hashable {

    /** The hashed checksum public address of the destination wallet. */
    public var destinationWallet: String?
    /** The Project being minted. */
    public var project: String?

    public init(destinationWallet: String? = nil, project: String? = nil) {
        self.destinationWallet = destinationWallet
        self.project = project
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case destinationWallet = "destination_wallet"
        case project
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(destinationWallet, forKey: .destinationWallet)
        try container.encodeIfPresent(project, forKey: .project)
    }
}

