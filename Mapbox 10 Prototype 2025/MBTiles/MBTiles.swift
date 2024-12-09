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

public struct MBTiles {
  public let path: String
  private let db: Connection

  private init(path: String, db: Connection) {
    self.path = path
    self.db = db
  }

  public static func open(path: String, readonly: Bool = false) throws -> MBTiles {
    // Check to make sure the specified path exists
    if !FileManager.default.fileExists(atPath: path) {
      throw NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT))
    }

    // Open a connection to the SQLite database file at 'path'
    let db = try Connection(path, readonly: readonly)

    // Make sure the SQLite database is a valid MBTiles file...

    do {
      // This query will fail if the table `metadata` does not exist, or
      // does not have `name` and `value` columns.
      let _ = try db.execute("SELECT name, value FROM metadata LIMIT 0")
    } catch {
      throw MBTilesValidationError.missingOrMalformedRequiredTable(name: "metadata")
    }

    do {
      // This query will fail if the table `tiles` doesn't exist, or
      // if it doesn't have the requisite columns.
      let _ = try db.execute("SELECT zoom_level, tile_column, tile_row, tile_data FROM tiles LIMIT 0")
    } catch {
      throw MBTilesValidationError.missingOrMalformedRequiredTable(name: "tiles")
    }

    // These two metadata properties are required by the MBTiles spec
    guard let _ = metadata(db: db, key: "name") else {
      throw MBTilesValidationError.missingRequiredMetadata(name: "name")
    }
    guard let _ = metadata(db: db, key: "format") else {
      throw MBTilesValidationError.missingRequiredMetadata(name: "format")
    }

    return MBTiles(path: path, db: db)
  }

  public static func create(path: String, name: String, format: TileFormat) throws -> MBTiles {
    // Check to make sure the specified path doesn't already exist
    if FileManager.default.fileExists(atPath: path) {
      throw NSError(domain: NSPOSIXErrorDomain, code: Int(EEXIST))
    }

    // Open a connection to the SQLite database file at 'path'
    let db = try Connection(path)

    try db.run("CREATE TABLE metadata (name text, value text)")
    try db.run("INSERT INTO metadata (name, value) VALUES ('name', ?)", name)
    try db.run("INSERT INTO metadata (name, value) VALUES ('format', ?)", format.rawValue)

    try db.run("CREATE TABLE tiles (zoom_level integer, tile_column integer, tile_row integer, tile_data blob)")
    try db.run("CREATE UNIQUE INDEX tile_index on tiles (zoom_level, tile_column, tile_row)")

    return MBTiles(path: path, db: db)
  }

  private static func metadata(db: Connection, key: String) -> String? {
    let metadata = Table("metadata")
      let name = SQLite.Expression<String>("name")
      let value = SQLite.Expression<String>("value")

    let query = metadata.select(value)
      .filter(name == key)
      .limit(1)

    guard let result = try? db.pluck(query) else { return nil }
    return result[value]
  }

  private func metadata(key: String) -> String? {
    return Self.metadata(db: db, key: key)
  }

  public var name: String {
    // force-unwrapping here is safe since we check for this key during initialization
    return metadata(key: "name")!
  }

  public var format: TileFormat {
    // force-unwrapping here is safe since we check for this key during initialization
    let format = metadata(key: "format")!
    return TileFormat(rawValue: format)
  }

  public var bounds: Bounds? {
    guard let bounds = metadata(key: "bounds") else { return nil }
    let components = bounds.split(separator: ",")
    let degrees = components.compactMap { CLLocationDegrees($0) }
    if components.count > degrees.count { return nil }
    return Bounds(array: degrees)
  }

  public var center: CameraPosition? {
    guard let center = metadata(key: "center") else { return nil }

    let components = center.split(separator: ",")
    if components.count != 3 { return nil }

    guard let longitude = CLLocationDegrees(components[0]) else { return nil }
    guard let latitude = CLLocationDegrees(components[1]) else { return nil }
    guard let zoom = Float(components[2]) else { return nil }

    return CameraPosition(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), zoom: zoom)
  }
  
  public var minZoom: Int? { Int(metadata(key: "minzoom") ?? "") }
  public var maxZoom: Int? { Int(metadata(key: "minzoom") ?? "") }

  public subscript(z z: Int, x x: Int, y y: Int) -> Data? {
    get {
      let tiles = Table("tiles")

        let zoom_level = SQLite.Expression<Int>("zoom_level")
        let tile_column = SQLite.Expression<Int>("tile_column")
        let tile_row = SQLite.Expression<Int>("tile_row")
        let tile_data = SQLite.Expression<Data>("tile_data")

      let query = tiles.select(tile_data)   // SELECT tile_data from tiles
                       .filter(zoom_level == z && tile_column == x && tile_row == y)
                                            // ... WHERE zoom_level == {z} AND tile_column == {x} AND tile_row == {y}
                       .limit(1)            // LIMIT 1 (valid MBTiles files shouldn't have more than one tile (z, x, y) anyways)

      guard let result = try? db.pluck(query) else { return nil }

      return result[tile_data]
    }

    set {
      let tiles = Table("tiles")

        let zoom_level = SQLite.Expression<Int>("zoom_level")
        let tile_column = SQLite.Expression<Int>("tile_column")
        let tile_row = SQLite.Expression<Int>("tile_row")
        let tile_data = SQLite.Expression<Data>("tile_data")

      if let data = newValue {
        let query = tiles.insert(zoom_level <- z, tile_column <- x, tile_row <- y, tile_data <- data)
        let _ = try? db.run(query)
      } else {
        let query = tiles.filter(zoom_level == z && tile_column == x && tile_row == y).delete()
        let _ = try? db.run(query)
      }
    }
  }
}
