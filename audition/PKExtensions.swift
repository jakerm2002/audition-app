//
//  PKExtensions.swift
//  audition
//
//  Created by Jake Medina on 2/24/25.
//
import PencilKit

/*
extension PKStroke: Identifiable {
    public var id: ObjectIdentifier {
        <#code#>
    }
}
*/

enum CodingKeys: String, CodingKey {
    case ink
    case path
    case transform
    case mask
}

extension PKStroke {
    func dataRepresentation() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let plistData = try encoder.encode(self)
        return plistData
    }
}

extension PKStroke: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
    }
    
    public init(from decoder: any Decoder) throws {
        <#code#>
    }
}
