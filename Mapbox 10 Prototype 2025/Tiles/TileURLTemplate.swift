//
//  TileURLTemplate.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/5/22.
//

import Foundation

/// A template string with {z}, {x}, and {y} placeholders that can be filled in to form a valid URL.
struct TileURLTemplate: RawRepresentable {
  typealias RawValue = String
  
  let rawValue: RawValue

  init(rawValue: RawValue) {
    self.rawValue = rawValue
  }

  init?(string: String) {
    // Check that the input string parses as a URL when the {placeholders} are removed
    let test = string
      .replacingOccurrences(of: "{z}", with: "0")
      .replacingOccurrences(of: "{x}", with: "0")
      .replacingOccurrences(of: "{y}", with: "0")
    guard let _ = URL(string: test) else { return nil }

    rawValue = string
  }

  func toURL(z: Int, x: Int, y: Int) -> URL {
    let result = rawValue
      .replacingOccurrences(of: "{z}", with: String(z))
      .replacingOccurrences(of: "{x}", with: String(x))
      .replacingOccurrences(of: "{y}", with: String(y))
    // force-unwrapping here is safe because we validated the URL in init()
    return URL(string: result)!
  }

  func toURL(tile: TileID) -> URL {
    return self.toURL(z: tile.z, x: tile.x, y: tile.y)
  }
}

extension TileURLTemplate: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    rawValue = try container.decode(String.self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
