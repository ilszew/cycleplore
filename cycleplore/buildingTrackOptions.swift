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
        NavigationStack {
            Form {
                Section(header: Text("Miejsce startowe").font(.headline)) {
                    HStack {
                        TextField("Wpisz adres", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: fetchCoordinates) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    
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
        Task {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(address)
                if let location = placemarks.first?.location {
                    startLocation = MapLocation(coordinate: location.coordinate)
                } else {
                    print("Nie udało się znaleźć współrzędnych dla adresu.")
                }
            } catch {
                print("Błąd geokodowania: \(error.localizedDescription)")
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
        NavigationStack {
            Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                if let location = startLocation {
                    Marker("Start", coordinate: location.coordinate)
                }
            }
            .mapControlVisibility(.visible)
            .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                Task {
                    if let coordinate = await getCenterCoordinate() {
                        startLocation = MapLocation(coordinate: coordinate)
                    }
                }
            })
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

    /// Pobiera współrzędne z centrum mapy
    private func getCenterCoordinate() async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let mapView = MKMapView()
                mapView.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )

                let coordinate = mapView.centerCoordinate
                continuation.resume(returning: coordinate)
            }
        }
    }
}

#Preview {
    BuildingTrackOptions()
}
