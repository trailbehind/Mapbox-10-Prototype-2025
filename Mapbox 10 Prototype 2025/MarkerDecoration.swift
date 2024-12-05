//
//  MarkerDecoration.swift
//  Mapbox 10 Prototype 2025
//
//  Created by Jim Margolis on 12/5/24.
//


enum MarkerDecoration: String, CaseIterable {
    case trailhead, campsite, cairn, cave, volcano
    case park, forest, geyser, peak, reef
    case scrub, attraction, binoculars, picnic, garden
    case snowflake, mud, grass, wetland, marsh
    case water
    case lake, waterfall
    case naturalSpring = "natural-spring"
    case hotSpring = "hotspring"
    case stone, cliff
    case sandDune = "sand-dune"
    case wood
    case treeFall = "tree-fall"
    case logging
    case oilWell = "oil-well"
    case mine, petroglyph, beach, fuel, restaurant, parking
    case potableWater = "potable-water"
    case shower, toilets, harbor, cafe, market
    case rangerStation = "ranger-station"
    case city
    case fireLookout = "fire-lookout"
    case building, museum, ruins, lighthouse, golf, cemetery, hospital, helipad
    case emergencyTelephone = "emergency-telephone"
    case chemist, resupply, danger, police, suitcase, minefield, trash
    case fastFood = "fast-food"
    case camera, electric, fish
    case discGolf = "disc-golf"
    case swimming, skiing, pitch, playground
    case knownRoute = "known-route"
    case canoe, climbing, snowmobile, disability, shelter
    case lodging, bicycle, airport, car, bus, rail, heliport, van
    case offRoad = "off-road"
    case rvPark = "rv-park"
    case mobilePhone = "mobilephone"
    case fireStation = "fire-station"
    case dam, steps, saddle, prison, railroad
    case fence, gate, bridge
    case treeStand = "tree-stand"
    case groundBlind = "ground-blind"
    case trailCamera = "trail-camera"
    case dogTrack = "track-dog"
    case deerTrack = "track-deer"
    case scat, turkey, horse
    case dogPark = "dog-park"
    case bear, moose, elk, deer, bird, mushroom
    case ghostTown = "ghost-town"
    case info = "information"
    case noAdmittance = "no-admittance-1"
    case noAdmittanceAlternate = "no-admittance-2"
    case pollingPlace = "polling-place"
    case circle, heart, square, triangle, star
    case bodyOfWater = "body-of-water"
    case zero = "number-0"
    case one = "number-1"
    case two = "number-2"
    case three = "number-3"
    case four = "number-4"
    case five = "number-5"
    case six = "number-6"
    case seven = "number-7"
    case eight = "number-8"
    case nine = "number-9"

    init?(rawValue: String?) {
      guard let markerDecoration = MarkerDecoration.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
      self = markerDecoration
    }
  }