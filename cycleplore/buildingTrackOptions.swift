import SwiftUI
import MapKit

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct BuildingTrackOptions: View {
    @State private var startLocation: MapLocation? = nil
    @State private var trackLength: Double = 20.0
    @State private var days: Int = 1
    @State private var fitnessLevel: Int = 1
    @State private var showFullScreenMap = false
    @State private var address: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Miejsce startowe").font(.headline)) {
                    TextField("Wpisz adres", text: $address, onCommit: fetchCoordinates)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: { showFullScreenMap = true }) {
                        HStack {
                            Text(startLocation == nil ? "Wybierz miejsce" : "Zmień lokalizację")
                            Spacer()
                            Image(systemName: "map")
                        }
                        .foregroundColor(.blue)
                    }
                }

                Section(header: Text("Parametry trasy").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Długość trasy: \(Int(trackLength)) km")
                        Slider(value: $trackLength, in: 20...200, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ilość dni: \(days)")
                        Slider(value: Binding(
                            get: { Double(days) },
                            set: { days = Int($0) }
                        ), in: 1...10, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sprawność: \(fitnessLevel)")
                        Picker("Sprawność", selection: $fitnessLevel) {
                            ForEach(1...5, id: \.self) { level in
                                Text("Poziom \(level)").tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                Section {
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
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Tworzenie trasy")
            .sheet(isPresented: $showFullScreenMap) {
                FullScreenMapView(startLocation: $startLocation)
            }
        }
    }

    /// Pobiera współrzędne dla wpisanego adresu
    private func fetchCoordinates() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let location = placemarks?.first?.location {
                startLocation = MapLocation(coordinate: location.coordinate)
            } else {
                print("Nie udało się znaleźć współrzędnych dla adresu.")
            }
        }
    }
}

// Pełnoekranowa mapa do wyboru miejsca startowego
struct FullScreenMapView: View {
    @Binding var startLocation: MapLocation?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                if let location = startLocation {
                    Marker("Start", coordinate: location.coordinate)
                }
            }
            .mapControlVisibility(.visible)
            .onTapGesture { location in
                Task {
                    if let coordinate = await convertPointToCoordinate(location) {
                        startLocation = MapLocation(coordinate: coordinate)
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        )
                    }
                }
            }
            .navigationTitle("Wybierz miejsce")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Konwertuje kliknięty punkt na mapie na współrzędne geograficzne
    private func convertPointToCoordinate(_ location: CGPoint) async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first,
                   let rootViewController = window.rootViewController {
                    let mapView = MKMapView()
                    mapView.frame = rootViewController.view.bounds
                    rootViewController.view.addSubview(mapView)

                    let point = mapView.convert(location, toCoordinateFrom: rootViewController.view)
                    rootViewController.view.subviews.forEach { $0.removeFromSuperview() }
                    continuation.resume(returning: point)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

#Preview {
    BuildingTrackOptions()
}
