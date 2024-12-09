//
//  Bounds.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/5/22.
//

import CoreLocation

/// Bounds represents a spherical bounding box—an area defined by minimum and maximum longitudes and latitudes.
public struct Bounds: Equatable {
  public var north: CLLocationDegrees
  public var south: CLLocationDegrees
  public var east: CLLocationDegrees
  public var west: CLLocationDegrees

  /// Create a bounds from an western-, southern-, eastern-, and northern limits (in degrees).
  public init(west: CLLocationDegrees, south: CLLocationDegrees, east: CLLocationDegrees, north: CLLocationDegrees) {
    self.west = west
    self.south = south
    self.east = east
    self.north = north
  }

  /// Create a bounds from an array of values representing the west, south, east and north limits.
  ///
  /// Fails if the array does not contain exactly four values.
  public init?(array: [CLLocationDegrees]) {
    if array.count != 4 { return nil }
    self.west = array[0]
    self.south = array[1]
    self.east = array[2]
    self.north = array[3]
  }

  /// Create a Bounds from a pair of coordinates representing the northeast and southwest corners.
  public init(northeast: CLLocationCoordinate2D, southwest: CLLocationCoordinate2D) {
    self.north = northeast.latitude
    self.south = southwest.latitude
    self.east = northeast.longitude
    self.west = southwest.longitude
  }

  public var northeast: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: self.north, longitude: self.east)  }
  public var southwest: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: self.south, longitude: self.west)  }

  public var northwest: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: self.north, longitude: self.west) }
  public var southeast: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: self.south, longitude: self.east) }

  /// Check if the bounding box contains a coordinate.
  public func contains(_ coord: CLLocationCoordinate2D) -> Bool {
    if (west < east) {
      // bounding box does not cross the antimeridian
      return south...north ~= coord.latitude && west...east ~= coord.longitude
    } else {
      // bounding box _does_ cross the antimeridian
      return south...north ~= coord.latitude && (west...180 ~= coord.longitude || -180...east ~= coord.longitude)
    }
  }
}

extension Bounds {
  /// The bounding box of the whole Earth (encompassing all valid latitudes and longitudes).
  public static let wholeEarth = Bounds(west: -180, south: -90, east: 180, north: 90)

  /// The bounding box of the square Mercator projection; encompasses all longitudes between ~85.05° North and South.
  public static let mercatorSquare = Bounds(west: -180, south: -85.051129, east: 180, north: 85.051129)
}

/// Bounds is Codable to and from a GeoJSON-style array of [west, south, east, north] values (in degrees).
extension Bounds: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()

    self.west = try container.decode(CLLocationDegrees.self)
    self.south = try container.decode(CLLocationDegrees.self)
    self.east = try container.decode(CLLocationDegrees.self)
    self.north = try container.decode(CLLocationDegrees.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(west)
    try container.encode(south)
    try container.encode(east)
    try container.encode(north)
  }
}
