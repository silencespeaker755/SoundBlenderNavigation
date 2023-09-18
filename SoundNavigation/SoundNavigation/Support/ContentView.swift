/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The top-level view for the app.
*/

import UIKit
import SwiftUI
import GoogleMaps
import MapKit
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
    @ObservedObject var audioEngine:SpatialAudioEngine = SpatialAudioEngine()
    
    @State var message:String = ""


    var body: some View {
        ZStack {
            MapView(withLatitude: $locationManager.withLatitude, longitude: $locationManager.longitude)
            SoundList(sources: $locationManager.sources, message: $message, waited: $audioEngine.currentID)
        }
        .onViewDidLoad{
            locationManager.requestPermission()
            firebaseManager.observeDetectionChanges(audioEngine: audioEngine, soundList: $locationManager.sources, message: $message, currentID: $audioEngine.currentID)
            let varTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true)
            { (varTimer) in
                if(!SoundNavigationApp.playingAvailable){
                    let index = Int.random(in: 1...1)
                    let soundInfo = audioEngine.soundMap[index]!
                    $message.wrappedValue = audioEngine.soundMap[index]!.message
                    audioEngine.soundPlay(soundInfo.soundSourceID, soundInfo.x, soundInfo.y, soundInfo.z)
                    SoundNavigationApp.isPlaying = true
                    SoundNavigationApp.someoneSpeeching = false
                    
                    let varTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false)
                    { (varTimer) in
                        $message.wrappedValue = ""
                        SoundNavigationApp.isPlaying = false
                        print("---------------Speech-----------:  " + String(SoundNavigationApp.someoneSpeeching))
                        if(SoundNavigationApp.someoneSpeeching) {
                            audioEngine.soundPlay(audioEngine.speechSourceID, 1, 1, 0)
                        }
                        SoundNavigationApp.someoneSpeeching = false
                    }
                }
                else{
                    let index = Int.random(in: 0...1)
                    $audioEngine.currentID.wrappedValue = index
                    $message.wrappedValue = audioEngine.soundMap[index]!.message
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
        do {
             // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
               mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
               print("Unable to find style.json")
            }
        } catch {
               print("One or more of the map styles failed to load. \(error)")
        }

        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if(MapView.updated < 10){
            uiView.moveCamera(GMSCameraUpdate.setCamera(GMSCameraPosition.init(latitude: withLatitude, longitude: longitude, zoom: 18.0)))
            print(MapView.updated)
        }
        if(MapView.updated == 10){
            setMapMarkersRoute(uiView, vLoc: CLLocationCoordinate2D(latitude: withLatitude, longitude: longitude), toLoc: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654))
        }
        MapView.updated += 1
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func setMapMarkersRoute(_ uiView: GMSMapView, vLoc: CLLocationCoordinate2D, toLoc: CLLocationCoordinate2D) {

        //add the markers for the 2 locations
//        let markerTo = GMSMarker.init(position: toLoc)
//        markerTo.map = uiView
//        let vMarker = GMSMarker.init(position: vLoc)
//        vMarker.map = uiView

        //zoom the map to show the desired area
        var bounds = GMSCoordinateBounds()
        bounds = bounds.includingCoordinate(vLoc)
        bounds = bounds.includingCoordinate(toLoc)
//        uiView.moveCamera(GMSCameraUpdate.fit(bounds))

        //finally get the route
        getRoute(uiView, from: vLoc, to: toLoc)

    }
    
    func getRoute(_ uiView: GMSMapView, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        
        let source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: to))

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        directions.calculate(completionHandler: { (response, error) in
            if let res = response {
                //the function to convert the result and show
                self.show(uiView, polyline: self.googlePolylines(from: res), outer: true)
                self.show(uiView, polyline: self.googlePolylines(from: res), outer: false)
            }
        })
    }
    
    private func googlePolylines(from response: MKDirections.Response) -> GMSPolyline {

        let route = response.routes[0]
        var coordinates = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: route.polyline.pointCount)

        route.polyline.getCoordinates(
            &coordinates,
            range: NSRange(location: 0, length: route.polyline.pointCount))

        let polyline = Polyline(coordinates: coordinates)
        let encodedPolyline: String = polyline.encodedPolyline
        let path = GMSPath(fromEncodedPath: encodedPolyline)
        return GMSPolyline(path: path)
        
    }
    
    func show(_ uiView: GMSMapView, polyline: GMSPolyline, outer: Bool) {

        //add style to polyline
        if(outer){
            let outlinePolyline = polyline
            outlinePolyline.strokeColor = UIColor(rgb: 0x1867d2)
            outlinePolyline.strokeWidth = 8.0
            outlinePolyline.map = uiView
        }
        else{
            let fillPolyline = polyline
            fillPolyline.strokeColor = UIColor(rgb: 0x00b0ff)
            fillPolyline.strokeWidth = 3.5
            fillPolyline.map = uiView
        }
    }

}

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

class Coordinator: NSObject, GMSMapViewDelegate {
    var parent: MapView

    init(_ parent: MapView) {
        self.parent = parent
    }
}
