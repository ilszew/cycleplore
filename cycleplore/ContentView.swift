import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: BuildingTrackOptions()){
                    MenuButton(title: "New adventure")
                }
                
                NavigationLink(destination: DownloadsViewControllerWrapper()) {
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

struct DownloadsViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        openDownloadsFolder()
    }
    
    func openDownloadsFolder() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("Selected files: \(urls)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
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
