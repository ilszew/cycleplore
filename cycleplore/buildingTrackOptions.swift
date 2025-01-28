import SwiftUI
import MapKit

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct buildingTrackOptions: View {
    @State private var startLocation: MapLocation? = nil
    @State private var trackLength: Double = 20.0
    @State private var days: Int = 1
    @State private var fitnessLevel: Int = 1
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var mapProxy: MapProxy? = nil  // konwersja punktow na wspolrzedne

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Miejsce startowe")
                    .font(.headline)
                Text("Wybierz miejsce na mapie")
                    .font(.subheadline)

                Map(position: $cameraPosition, interactionModes: .all) {
                    if let location = startLocation {
                        Marker("Start", coordinate: location.coordinate)
                    }
                }
                .frame(height: 300)
                .mapControlVisibility(.visible)
                .overlay {
                    MapReader { proxy in
                        Color.clear.onAppear {
                            mapProxy = proxy  // do pozniejszego uzycia
                        }
                    }
                }
                .onTapGesture { point in
                    if let mapProxy, let tappedLocation = mapProxy.convert(point, from: .local) {
                        startLocation = MapLocation(coordinate: tappedLocation)
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: tappedLocation,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        )
                    }
                }

                Text("Długość trasy: \(Int(trackLength)) km")
                    .font(.headline)
                Slider(value: $trackLength, in: 20...200, step: 1)

                Text("Ilość dni: \(days)")
                    .font(.headline)
                Slider(value: Binding(
                    get: { Double(days) },
                    set: { days = Int($0) }
                ), in: 1...10, step: 1)

                Text("Sprawność: \(fitnessLevel)")
                    .font(.headline)
                Picker("Sprawność", selection: $fitnessLevel) {
                    ForEach(1...5, id: \.self) { level in
                        Text("Poziom \(level)").tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Spacer()

                Button(action: {
                    if let startLocation = startLocation {
                        print("Miejsce startowe: \(startLocation.coordinate.latitude), \(startLocation.coordinate.longitude)")
                    } else {
                        print("Miejsce startowe nie zostało wybrane")
                    }
                    print("Długość trasy: \(Int(trackLength)) km")
                    print("Ilość dni: \(days)")
                    print("Sprawność: \(fitnessLevel)")
                }) {
                    Text("Zatwierdź")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Tworzenie trasy")
        }
    }
}
