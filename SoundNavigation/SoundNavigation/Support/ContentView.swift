/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The top-level view for the app.
*/

import SwiftUI
import GoogleMaps
import CoreLocation

struct ViewDidLoadModifier: ViewModifier {
    @State private var viewDidLoad = false
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if viewDidLoad == false {
                    viewDidLoad = true
                    action?()
                }
            }
    }
}

extension View {
    func onViewDidLoad(perform action: (() -> Void)? = nil) -> some View {
        self.modifier(ViewDidLoadModifier(action: action))
    }
}

/// The main view that contains the app content.
struct ContentView: View {
    @ObservedObject var locationManager:LocationModel = LocationModel()
    var firebaseManager:FirebaseManager = FirebaseManager()
    var audioEngine:SpatialAudioEngine = SpatialAudioEngine()


    var body: some View {
        ZStack {
            MapView(withLatitude: $locationManager.withLatitude, longitude: $locationManager.longitude)
        }
        .onViewDidLoad{
            locationManager.requestPermission()
            firebaseManager.observeDetectionChanges(audioEngine: audioEngine)
            let varTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false)
            { (varTimer) in
                if(!SoundNavigationApp.playingAvailable){
                    let soundInfo = audioEngine.soundMap[Int.random(in: 0...1)]!
                    audioEngine.soundPlay(soundInfo.soundSourceID, soundInfo.x, soundInfo.y, soundInfo.z)
                }
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    
    @Binding var withLatitude: CGFloat
    @Binding var longitude: CGFloat
    
    static var updated:Int = 0
    
    typealias UIViewType = GMSMapView
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: withLatitude, longitude: longitude, zoom: 18.0)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        print("updating")
        if(MapView.updated < 5){
            uiView.moveCamera(GMSCameraUpdate.setCamera(GMSCameraPosition.init(latitude: withLatitude, longitude: longitude, zoom: 18.0)))
            MapView.updated += 1
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class Coordinator: NSObject, GMSMapViewDelegate {
    var parent: MapView

    init(_ parent: MapView) {
        self.parent = parent
    }

    // 您可以在這裡實現地圖事件的處理程序
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
