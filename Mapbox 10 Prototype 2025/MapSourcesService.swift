//
//  MapSourcesService.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/5/22.
//

import Foundation

/// MapSourcesService provides access to information about available map sources.
/// This information is fetched from the mapSourcesV2.json file bundled with the application.
/// TODO: This service also needs to periodically refresh the map sources data from Gaia Cloud.
class MapSourcesService {
  static let shared = MapSourcesService()!

  var sources: [String: MapSource] = [:]

  private init?() {
    if let path = Bundle.main.path(forResource: "mapSourcesV2", ofType: "json") {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let sourcesFile = try JSONDecoder().decode(Self.MapSourcesFile, from: data)
        self.sources = Dictionary(sourcesFile.mapSources.map { ($0.id, $0) }, uniquingKeysWith: { (_, last) in last })
      } catch {
        return nil
      }
    }
  }

  struct MapSourcesFile: Codable {
    let mapSources: [MapSource]
  }
}
