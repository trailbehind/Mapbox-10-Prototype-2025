//
//  MBTilesReader.swift
//  Mapbox 10 prototype
//
//  Created by Jake Low on 1/18/22.
//

enum MBTilesValidationError: Error {
  case missingRequiredMetadata(name: String)
  case missingOrMalformedRequiredTable(name: String)
}
