//
//  PKExtensions.swift
//  audition
//
//  Created by Jake Medina on 2/24/25.
//
import PencilKit
import CryptoKit

/*
extension PKStroke: Identifiable {
    public var id: ObjectIdentifier {
        <#code#>
    }
}
*/

let PKAppleStrokeTypeIdentifier: String = "PKAppleStrokeTypeIdentifier"

extension PKStroke {
    func dataRepresentation() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let plistData = try encoder.encode(self)
        return plistData
    }
}

extension PKStroke {
    public init(from data: Data) throws {
        do {
            self = try PropertyListDecoder().decode(PKStroke.self, from: data)
        } catch let error {
            throw AuditionError.runtimeError("error: Failed to decode Data to PKStroke: \(error)")
        }
    }
}

extension PKInkingTool.InkType: Codable {}

extension PKStroke: Plistable {
    var plist: Data {
        get throws {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            let plistData = try encoder.encode(self)
            return plistData
        }
    }
}

extension PKStroke: SHA256Hashable {
    var sha256DigestObject: SHA256Digest? {
        do {
            return SHA256.hash(data: try plist)
        } catch {
            print("Unable to serialize \(PKStroke.self) to plist")
            return nil
        }
    }
    
    var sha256DigestValue: String? {
        return sha256DigestObject?.hexString
    }
}

extension PKStroke: Codable {
    enum CodingKeys: String, CodingKey {
        case ink
        case path
        case transform
        case mask
        case randomSeed
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // encode ink
        try container.encode(ink, forKey: .ink)
        
        // encode path
        try container.encode(path, forKey: .path)
        
        // encode transform
        try container.encode(transform, forKey: .transform)
        
        // encode mask
        if let mask {
            // TODO: encode with a secure coding (make mask's type implement NSSecureCoding)
            let maskData = try NSKeyedArchiver.archivedData(withRootObject: mask, requiringSecureCoding: false)
            try container.encode(maskData, forKey: .mask)
        }
        
        try container.encode(randomSeed, forKey: .randomSeed)
    }
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // decode ink
        let ink = try values.decode(PKInk.self, forKey: .ink)
        
        // decode path
         let path = try values.decode(PKStrokePath.self, forKey: .path)
        
        // decode transform
        let transform = try values.decode(CGAffineTransform.self, forKey: .transform)
        
        // decode mask
        var mask: UIBezierPath? = nil
        if let maskData = try values.decodeIfPresent(Data.self, forKey: .mask) {
            guard let decodedMask = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: maskData) else {
                throw AuditionError.runtimeError("There was an unknown error when decoding PKStroke.mask")
            }
            mask = decodedMask
        }
        
        let randomSeed = try values.decode(UInt32.self, forKey: .randomSeed)
        
        self.init(ink: ink, path: path, transform: transform, mask: mask, randomSeed: randomSeed)
    }
}

extension PKInk: Codable {
    enum CodingKeys: String, CodingKey {
        case inkType
        case color
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(inkType, forKey: .inkType)
        
        // TODO: figure out if we can encode color with a secure coding?
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
    }
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let inkType = try values.decode(PKInk.InkType.self, forKey: .inkType)
        let colorData = try values.decode(Data.self, forKey: .color)
        guard let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) else {
            throw AuditionError.runtimeError("There was an unknown error when decoding PKInk.color")
        }
        
        self.init(inkType, color: color)
    }
}

extension PKStrokePath: Codable {
    enum CodingKeys: String, CodingKey {
        case controlPoints
        case creationDate
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // build an array of control points, then encode it
        var controlPoints = [PKStrokePoint]()
        for point in self {
            controlPoints.append(point)
        }
        
        try container.encode(controlPoints, forKey: .controlPoints)
        try container.encode(creationDate, forKey: .creationDate)
    }
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let controlPoints = try values.decode([PKStrokePoint].self, forKey: .controlPoints)
        let creationDate = try values.decode(Date.self, forKey: .creationDate)
        
        self.init(controlPoints: controlPoints, creationDate: creationDate)
    }
}

extension PKStrokePoint: Codable {
    enum CodingKeys: String, CodingKey {
        case location
        case timeOffset
        case altitude
        case azimuth
        case force
        case size
        case opacity
        case secondaryScale
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location, forKey: .location)
        try container.encode(timeOffset, forKey: .timeOffset)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(azimuth, forKey: .azimuth)
        try container.encode(force, forKey: .force)
        try container.encode(size, forKey: .size)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(secondaryScale, forKey: .secondaryScale)
    }
    
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let location = try values.decode(CGPoint.self, forKey: .location)
        let timeOffset = try values.decode(TimeInterval.self, forKey: .timeOffset)
        let altitude = try values.decode(CGFloat.self, forKey: .altitude)
        let azimuth = try values.decode(CGFloat.self, forKey: .azimuth)
        let force = try values.decode(CGFloat.self, forKey: .force)
        let size = try values.decode(CGSize.self, forKey: .size)
        let opacity = try values.decode(CGFloat.self, forKey: .opacity)
        let secondaryScale = try values.decode(CGFloat.self, forKey: .secondaryScale)
        
        self.init(
            location: location,
            timeOffset: timeOffset,
            size: size,
            opacity: opacity,
            force: force,
            azimuth: azimuth,
            altitude: altitude,
            secondaryScale: secondaryScale
        )
    }
}
