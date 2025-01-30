import SwiftUI
import MapKit

class TrackData: ObservableObject {
    @Published var startLocation: MapLocation? = nil
    @Published var trackLength: Double = 20.0
    @Published var days: Int = 1
    @Published var fitnessLevel: Int = 1
}
