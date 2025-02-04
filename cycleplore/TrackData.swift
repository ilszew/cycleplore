import SwiftUI
import MapKit
import UniformTypeIdentifiers
import UIKit

class TrackData: ObservableObject {
    @Published var startLocation: CLLocationCoordinate2D? = nil
    @Published var trackLength: Double = 20.0
    @Published var days: Int = 1
    @Published var fitnessLevel: Int = 1
    @Published var route: [CLLocationCoordinate2D] = []
    
    func generateRandomDestination() {
        guard let start = startLocation else { return }
        
        let earthRadius: Double = 6371.0 // km
        let distanceRatio = trackLength / earthRadius
        let randomBearing = Double.random(in: 0...(2 * .pi))
        
        let startLat = start.latitude.toRadians()
        let startLon = start.longitude.toRadians()
        
        let destLat = asin(sin(startLat) * cos(distanceRatio) + cos(startLat) * sin(distanceRatio) * cos(randomBearing))
        let destLon = startLon + atan2(sin(randomBearing) * sin(distanceRatio) * cos(startLat), cos(distanceRatio) - sin(startLat) * sin(destLat))
        
        let destination = CLLocationCoordinate2D(latitude: destLat.toDegrees(), longitude: destLon.toDegrees())
        
        route = [start, destination]
    }
    
    func openDownloadsFolder() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
        documentPicker.delegate = rootViewController as? UIDocumentPickerDelegate
        documentPicker.allowsMultipleSelection = true
        rootViewController.present(documentPicker, animated: true, completion: nil)
    }
    
    func saveGPXFile() {
        let gpxContent = generateGPX()
        let fileName = "track.gpx"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try gpxContent.write(to: fileURL, atomically: true, encoding: .utf8)
            shareFile(fileURL)
        } catch {
            print("Error saving GPX file: \(error)")
        }
    }
    
    private func generateGPX() -> String {
        var gpx = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gpx += "<gpx version=\"1.1\" creator=\"Cycleplore\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        gpx += "<trk>\n<trkseg>\n"
        
        for coord in route {
            gpx += "<trkpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\"/>\n"
        }
        
        gpx += "</trkseg>\n</trk>\n</gpx>"
        return gpx
    }
    
    private func shareFile(_ fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}
