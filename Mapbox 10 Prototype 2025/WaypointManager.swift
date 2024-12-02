//
//  WaypointManager.swift
//  Mapbox 10 Prototype 2025
//
//  Created by Jim Margolis on 12/2/24.
//

import MapboxMaps

struct Waypoint {
    var latitude: Double
    var longitude: Double
}

class WaypointManager {
    static let shared = WaypointManager()

    var waypoints: [Waypoint] = []

    private init() {
        waypoints = generateWaypoints() // Simulate fetching from CoreData
    }

    private func generateWaypoints() -> [Waypoint] {
        var generatedWaypoints: [Waypoint] = []
        
        let centerLatitude = 47.42
        let centerLongitude = -121.425
        
        let spacing = 0.1
        
        for _ in 0..<100 {
            let latitude = centerLatitude + Double.random(in: -spacing...spacing)
            let longitude = centerLongitude + Double.random(in: -spacing...spacing)
            
            let waypoint = Waypoint(latitude: latitude, longitude: longitude)
            generatedWaypoints.append(waypoint)
        }
        
        return generatedWaypoints
    }
}

struct TileID {
    let x: Int
    let y: Int
    let zoom: Int
}



class WaypointDataSource {
    static let shared = WaypointDataSource()
    
    func getWaypointsForTile(tileID: TileID) -> [Feature] {
        let waypoints = WaypointManager.shared.waypoints
        return waypoints.compactMap { waypoint in
            // Calculate the tileID for the waypoint
            let waypointTileID = MathHelper.getTileID(latitude: waypoint.latitude, longitude: waypoint.longitude, zoom: tileID.zoom)
            
            // Check if the waypoint is within the correct tile bounds
            if waypointTileID.x == tileID.x && waypointTileID.y == tileID.y {
                // Create and return a Feature object if the waypoint matches the tile
                let coordinate = CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude)
                let point = Point(coordinate)
                let feature = Feature(geometry: .point(point))
                return feature
            } else {
                // Return nil if the waypoint does not belong to the given tile
                return nil
            }
        }
    }
}

class MathHelper {
    static func getTileID(latitude: Double, longitude: Double, zoom: Int) -> TileID {
        let n = pow(2.0, Double(zoom))
        let x = Int((longitude + 180.0) / 360.0 * n)
        let y = Int((1.0 - log(tan(latitude * .pi / 180.0) + 1.0 / cos(latitude * .pi / 180.0)) / .pi) / 2.0 * n)
        return TileID(x: x, y: y, zoom: zoom)
    }
}
