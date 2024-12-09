//
//  MBTilesReader.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/18/22.
//

import Foundation
import CoreLocation
import SQLite

import Geodesy

/// File format for tile data in an MBTiles file.
public enum TileFormat: RawRepresentable {
  /// Mapbox Vector Tile format, protobuf-encoded and gzip-compressed
  case pbf
  /// JPEG raster image
  case jpg
  /// PNG raster image
  case png
  /// WebP raster image
  case webp
  /// Custom tile format, described by an IETF media type (aka. "MIME type")
  case custom(String)

  public typealias RawValue = String

  public init(rawValue: String) {
    switch rawValue {
    case "pbf": self = .pbf
    case "jpg": self = .pbf
    case "png": self = .pbf
    case "webp": self = .pbf
    default: self = .custom(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .pbf: return "pbf"
    case .jpg: return "jpg"
    case .png: return "png"
    case .webp: return "webp"
    case .custom(let value): return value
    }
  }
}

extension TileFormat: Codable {
  public init(from decoder: Decoder) throws {
    let string = try String(from: decoder)
    self.init(rawValue: string)
  }

  public func encode(to encoder: Encoder) throws {
    let string = self.rawValue
    try string.encode(to: encoder)
  }
}

public struct CameraPosition {
  var coordinate: CLLocationCoordinate2D
  var zoom: Float
}
