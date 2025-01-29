import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                
                NavigationLink(destination: BuildingTrackOptions()){
                    MenuButton(title: "New adventure")
                }
                
                NavigationLink(destination: previousTracks()) {
                    MenuButton(title: "Previous adventures")
                }
                
                NavigationLink(destination: settings()) {
                    MenuButton(title: "Settings")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("cycleplore")
        }
    }
}

struct MenuButton: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct previousTracks: View {
    var body: some View {
        VStack {
            Text("Ekran 2")
                .font(.largeTitle)
                .foregroundColor(.green)
        }
        .navigationTitle("Ekran 2")
    }
}

struct settings: View {
    var body: some View {
        VStack {
            Text("Ekran 3")
                .font(.largeTitle)
                .foregroundColor(.yellow)
        }
        .navigationTitle("Ekran 3")
    }
}


