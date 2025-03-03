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

enum PKInkCodingKeys: String, CodingKey {
    case inkType
    case color
}

extension PKStroke {
    func dataRepresentation() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let plistData = try encoder.encode(self)
        return plistData
    }
}

extension PKInkingTool.InkType: Codable {}

extension PKStroke: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // encode ink
        var inkInfo = container.nestedContainer(keyedBy: PKInkCodingKeys.self, forKey: .ink)
        try inkInfo.encode(ink.inkType, forKey: .inkType)
        
        let colorInfo = try NSKeyedArchiver.archivedData(withRootObject: ink.color, requiringSecureCoding: false)
        try inkInfo.encode(colorInfo, forKey: .color)
        
        // TODO: encode path
        
        // encode transform
        try container.encode(transform, forKey: .transform)
        
        // TODO: encode mask
        if let mask {
            let maskInfo = try NSKeyedArchiver.archivedData(withRootObject: mask, requiringSecureCoding: false)
            try container.encode(maskInfo, forKey: .mask)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        <#code#>
    }
}
