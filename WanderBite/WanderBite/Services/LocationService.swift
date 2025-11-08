import Foundation
import Combine
import CoreLocation

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published private(set) var city: String? = nil

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            default:
                break
            }
        } else {
            switch type(of: manager).authorizationStatus() {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            default:
                break
            }
        }
    }

    // Modern delegate (iOS 14+)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    // Legacy delegate (prior to iOS 14)
    @available(iOS, introduced: 4.2, deprecated: 14.0)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        manager.stopUpdatingLocation()

        if #available(iOS 26, *) {
            // TODO: Replace with MapKit-based reverse geocoding when targeting an SDK that provides it.
            // Keep using Core Location for now to maintain functionality on current SDKs.
        } else {
            // Use CLGeocoder on iOS versions prior to 26 to avoid deprecation warnings.
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
                guard let self = self else { return }
                if let placemark = placemarks?.first {
                    DispatchQueue.main.async {
                        self.city = placemark.locality
                    }
                }
            }
        }
    }
}
