import SwiftUI
import MapKit

struct MapLocation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct BuildingTrackOptions: View {
    @State private var startLocation: MapLocation?
    @State private var trackLength: Double = 20.0
    @State private var days: Int = 1
    @State private var fitnessLevel: Int = 1
    @State private var showFullScreenMap = false
    @State private var address: String = ""
    @State private var showingGeocodeError = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Wpisz adres", text: $address)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: fetchCoordinates) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .symbolEffect(.bounce, value: isLoading)
                            }
                        }
                        .disabled(isLoading)
                    }
                    
                    Button {
                        showFullScreenMap = true
                    } label: {
                        Label(
                            startLocation == nil ? "Wybierz na mapie" : "Zmień lokalizację",
                            systemImage: "mappin.and.ellipse"
                        )
                    }
                    .buttonStyle(.bordered)
                } header: {
                    Text("Miejsce startowe")
                        .font(.headline)
                }

                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Długość trasy:")
                            Spacer()
                            Text("\(Int(trackLength)) km")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $trackLength, in: 20...200, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Ilość dni:")
                            Spacer()
                            Text("\(days)")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(days) },
                                set: { days = Int($0) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Poziom sprawności:")
                        Picker("Sprawność", selection: $fitnessLevel) {
                            ForEach(1...5, id: \.self) { level in
                                Text("\(level)")
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } header: {
                    Text("Parametry trasy")
                        .font(.headline)
                }

                Section {
                    Button(action: handleSubmission) {
                        Text("Zatwierdź")
                            .frame(maxWidth: .infinity)
                            .contentTransition(.numericText())
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(startLocation == nil)
                }
            }
            .navigationTitle("Tworzenie trasy")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFullScreenMap) {
                FullScreenMapView(startLocation: $startLocation)
            }
            .alert("Błąd lokalizacji", isPresented: $showingGeocodeError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func fetchCoordinates() {
        isLoading = true
        Task {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(address)
                guard let location = placemarks.first?.location else {
                    showingGeocodeError = true
                    return
                }
                startLocation = MapLocation(coordinate: location.coordinate)
            } catch {
                showingGeocodeError = true
            }
            isLoading = false
        }
    }

    private func handleSubmission() {
        print("""
        Start: \(startLocation?.coordinate.latitude ?? 0),
        \(startLocation?.coordinate.longitude ?? 0)
        Długość: \(Int(trackLength)) km
        Dni: \(days)
        Poziom: \(fitnessLevel)
        """)
    }
}

struct FullScreenMapView: View {
    @Binding var startLocation: MapLocation?
    @State private var cameraPosition: MapCameraPosition
    @Environment(\.dismiss) var dismiss

    init(startLocation: Binding<MapLocation?>) {
        self._startLocation = startLocation
        let center = startLocation.wrappedValue?.coordinate ?? .warsaw
        self._cameraPosition = State(initialValue: .region(.init(
            center: center,
            span: .init(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let coordinate = startLocation?.coordinate {
                    Annotation("Start", coordinate: coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .opacity(0.8)
                            .scaleEffect(1.2)
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            // 🟢 Kliknięcie dodaje pinezkę i zamyka mapę
            .onTapGesture { tapLocation in
                if let coordinate = proxy.convert(tapLocation, from: .local) {
                    startLocation = MapLocation(coordinate: coordinate)
                    dismiss() // Automatyczne zamknięcie
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Wybierz start")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension CLLocationCoordinate2D {
    static let warsaw = CLLocationCoordinate2D(
        latitude: 52.2297,
        longitude: 21.0122
    )
}

#Preview {
    BuildingTrackOptions()
}
