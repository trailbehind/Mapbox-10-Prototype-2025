//
//  TileID.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 2/1/22.
//

/// Identifies a tile in tiled map.
///
/// Conventionally, web maps are based on the Web Mercator projection (EPSG:3857), clipped to a square (± ~85.05° N/S),
/// and then subdivided recursively into square tiles. Each recursive division is called a zoom level. At zoom level 0, the whole
/// extent of the map fits in one tile. At zoom level 1, the map is cut into a 2x2 tile grid; zoom level 2 is a 4x4 tile grid, and so on.
///
/// Tiles are uniquely identified by the zoom level, and by their row and column index in the grid for that zoom level. The math
/// for converting between geographic coordinates and Tile IDs is straightforward, which makes it easy for applications to load
/// only the tiles they need to cover the visible region of the map.
///
/// TileIDs don't know anything about which tile source they reference, or how to retrieve the tile they identify. To find the tile ID
/// that contains a geographic coordinate, use a ``TileTree``. When downloading tiles over HTTP, a ``TileURLTemplate``
/// may help to construct suitable URLs from tile IDs.
struct TileID: Equatable {
  let z: Int
  let x: Int
  let y: Int
}

