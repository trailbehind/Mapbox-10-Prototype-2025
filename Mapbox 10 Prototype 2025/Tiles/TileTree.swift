//
//  TileTree.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 2/1/22.
//

import CoreLocation
import Geodesy

/// Represents a set of `TileID`s, defined by a tile numbering scheme, geographic bounding box, and zoom range.
///
/// It provides methods to help find the right tile ID for a given coordinate and desired zoom.
///
/// Tile trees are agnostic to the details of actually retrieving tiles. A `TileTree` does not store a URL template or provide
/// ways to fetch tiles; it's just a helper for doing math to convert between tile IDs and geographic coordinates.
struct TileTree {
  let scheme: TileServiceScheme
  let bounds: Bounds
  let zooms: ClosedRange<Int>

  /// Get the tile ID containing a given coordinate at a particular discrete zoom level.
  func coordToTileID(_ coord: CLLocationCoordinate2D, zoom: Int) -> TileID? {
    guard bounds.contains(coord) else { return nil }
    guard zooms ~= zoom else { return nil }

    let z = Double(zoom)
    let x = Int(pow(2, z) * (coord.longitude + 180) / 360)
    let y = Int(pow(2, z - 1) * (1 - log( tan(deg2rad(coord.latitude)) + 1 / cos(deg2rad(coord.latitude)) ) / .pi ))

    return TileID(z: zoom, x: x, y: y)
  }

  /// Get the tile ID containing a given coordinate at a particular zoom value.
  /// The zoom is rounded up to the next integer value
  func coordToTileID(_ coord: CLLocationCoordinate2D, zoom: Double) -> TileID? {
    return coordToTileID(coord, zoom: Int(ceil(zoom)))
  }

  /// Get all the tile IDs required to fully cover a geographic bounding box at a particular zoom level.
  func tileIDs(in bounds: Bounds, zoom: Int) -> [TileID]? {
    guard let northwest = coordToTileID(bounds.northwest, zoom: zoom) else { return nil }
    guard let southeast = coordToTileID(bounds.southeast, zoom: zoom) else { return nil }

    var tiles: [TileID] = []

    for y in northwest.y...southeast.y {
      for x in northwest.x...southeast.x {
        tiles.append(TileID(z: zoom, x: x, y: y))
      }
    }

    return tiles
  }

  /// Get all the tile IDs required to fully cover a geographic bounding box over a range of zoom levels.
  func tileIDs(in bounds: Bounds, zooms: ClosedRange<Int>) -> [TileID]? {
    var tilesForAllZooms: [TileID] = []

    for zoom in zooms {
      guard let tilesForThisZoom = tileIDs(in: bounds, zoom: zoom) else { return nil }
      tilesForAllZooms.append(contentsOf: tilesForThisZoom)
    }

    return tilesForAllZooms
  }
}

// MARK: helper functions

fileprivate func deg2rad(_ number: Double) -> Double {
  return number * .pi / 180
}

