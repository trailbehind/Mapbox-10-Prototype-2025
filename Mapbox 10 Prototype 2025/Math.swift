//
//  Math.swift
//  Mapbox 10 Prototype 2025
//
//  Created by Jim Margolis on 12/5/24.
//

import MapboxMaps

class Math {
    static func boundsFromTile(_ tile: CanonicalTileID) -> BoundingBox {
        let tilesAtThisZoom = 1 << tile.z
        let width = 360.0 / Double(tilesAtThisZoom)
        
        let southwestLongitude = -180 + (Double(tile.x) * width)
        let northeastLongitude = southwestLongitude + width
        
        let latHeightMerc = 1.0 / Double(tilesAtThisZoom)
        let topLatMerc = Double(tile.y) * latHeightMerc
        let bottomLatMerc = topLatMerc + latHeightMerc
        
        let southwestLatitude = (180 / .pi) * (2 * atan(exp(.pi * (1 - (2 * bottomLatMerc)))) - (.pi / 2))
        let northeastLatitude = (180 / .pi) * (2 * atan(exp(.pi * (1 - (2 * topLatMerc)))) - (.pi / 2))
        
        return BoundingBox(
            northeastLatitude: northeastLatitude,
            northeastLongitude: northeastLongitude,
            southwestLatitude: southwestLatitude,
            southwestLongitude: southwestLongitude
        )
    }
    
    static func bufferBounds(bounds: BoundingBox, buffer: CGFloat) -> BoundingBox {
        let xSpan = abs(bounds.northeastLongitude - bounds.southwestLongitude)
        let ySpan = abs(bounds.northeastLatitude - bounds.southwestLatitude)
        
        let bufferedNortheastLongitude = min(bounds.northeastLongitude + xSpan * Double(buffer), 180)
        let bufferedSouthwestLongitude = max(bounds.southwestLongitude - xSpan * Double(buffer), -180)
        let bufferedNortheastLatitude = min(bounds.northeastLatitude + ySpan * Double(buffer), 90)
        let bufferedSouthwestLatitude = max(bounds.southwestLatitude - ySpan * Double(buffer), -90)
        
        return BoundingBox(
            northeastLatitude: bufferedNortheastLatitude,
            northeastLongitude: bufferedNortheastLongitude,
            southwestLatitude: bufferedSouthwestLatitude,
            southwestLongitude: bufferedSouthwestLongitude
        )
    }
}

struct BoundingBox {
    let northeastLatitude: Double
    let northeastLongitude: Double
    let southwestLatitude: Double
    let southwestLongitude: Double

    func contains(latitude: Double, longitude: Double) -> Bool {
        return latitude >= southwestLatitude &&
               latitude <= northeastLatitude &&
               longitude >= southwestLongitude &&
               longitude <= northeastLongitude
    }
}
