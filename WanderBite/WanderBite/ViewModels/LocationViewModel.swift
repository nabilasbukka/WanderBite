//
//  LocationViewModel.swift
//  WanderBite
//
//  Created by Afina R. Vinci on 11/9/25.
//
import CoreLocation
import MapKit
import Combine

class CityLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var city: String = "…"
    private let locationManager = CLLocationManager()
    private let fallbackCity = "Singapore"
    private var didSetCity = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        requestLocation()
    }
    
    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.updateCity(to: fallbackCity)
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            self.updateCity(to: fallbackCity)
        }
    }
    
    private func updateCity(to name: String) {
        guard !didSetCity else { return }
        DispatchQueue.main.async {
            self.city = name
            self.didSetCity = true
        }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            updateCity(to: fallbackCity)
            return
        }
        Task {
            let request = MKReverseGeocodingRequest(location: location)
            let mapitems = try? await request?.mapItems
            if let mapitem = mapitems?.first {
                let name = mapitem.addressRepresentations?.cityName
                if let cityName = name {
                    self.updateCity(to: cityName)
                } else {
                    self.updateCity(to: self.fallbackCity)
                }
            } else {
                self.updateCity(to: self.fallbackCity)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        updateCity(to: fallbackCity)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocation()
    }
}
