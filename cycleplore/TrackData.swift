import SwiftUI
import MapKit
import UniformTypeIdentifiers
import UIKit

class TrackData: ObservableObject {
    @Published var startLocation: CLLocationCoordinate2D? = nil
    @Published var trackLength: Double = 20.0
    @Published var route: [CLLocationCoordinate2D] = []
    
    func findNearestTrainStation() {
        guard let start = startLocation else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "stacja kolejowa"
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(center: start, latitudinalMeters: trackLength * 1000, longitudinalMeters: trackLength * 1000)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, let station = response.mapItems.first else {
                print("Brak stacji kolejowej w pobliżu.")
                return
            }
            
            DispatchQueue.main.async {
                self.route = [start, station.placemark.coordinate]
                self.saveGPXFile()
            }
        }
    }
    
    func saveGPXFile() {
        let gpxContent = generateGPX()
        let fileName = "track.gpx"
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try gpxContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("GPX file saved at: \(fileURL.path)")
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
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]
        
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
}
