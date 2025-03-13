//
//  ViewController.swift
//  NearMe
//
//  Created by Alexandre Marques on 3/5/25.
//
import UIKit
import MapKit

class ViewController: UIViewController {

    var locationManager: CLLocationManager?

    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true

        return map
    }()

    private lazy var searchTextField: UITextField = {
        let textField = UITextField()

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.clipsToBounds = true
        textField.placeholder = "Search"
        textField.delegate = self
        textField.textColor = UIColor.black
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 10
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.leftView = UIView(
            frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.returnKeyType = .go

        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.requestLocation()

        setupView()
    }

    private func setupView() {
        setHierarchy()
        setConstrants()
    }

    private func setHierarchy() {
        view.addSubview(searchTextField)
        view.addSubview(mapView)
        view.bringSubviewToFront(searchTextField)
    }

    private func setConstrants() {
        //        mapView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        //        mapView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        //
        //        mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        //        mapView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        NSLayoutConstraint.activate([
            mapView.widthAnchor.constraint(equalTo: view.widthAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor),
            mapView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mapView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            searchTextField.heightAnchor.constraint(equalToConstant: 44),
//            searchTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
//            searchTextField.widthAnchor.constraint(
//                equalToConstant: view.bounds.size.width / 1.2),
        ])

    }

    private func checkLocationAuthorization() {
        guard let locationManager = locationManager,
            let location = locationManager.location
        else { return }

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            let region = MKCoordinateRegion(
                center: location.coordinate, latitudinalMeters: 800,
                longitudinalMeters: 800)
            mapView.setRegion(region, animated: true)

        case .denied:
            print("Location services has been denied.")
        case .notDetermined, .restricted:
            print("Location cannot be determined or restricted.")
        @unknown default:
            print("Unknown error. Unable to get location.")
        }

    }
    
    private func presentPlacesSheet(places: [PlaceAnnotation]) {
        
        guard let locationManager = locationManager,
        let userLocation = locationManager.location
        else { return }
        
        let placesTVC = PlacesTableViewController(userLocation: userLocation, places: places)
        placesTVC.modalPresentationStyle = .pageSheet
        
        if let sheet = placesTVC.sheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium(), .large()]
            present(placesTVC, animated: true)
        }
    }
    
    private func findNearbyPlaces(by query: String) {
        
        // clear all annotations
        mapView.removeAnnotations(mapView.annotations)
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            
            guard let response = response, error == nil else { return }
            
            let places = response.mapItems.map(PlaceAnnotation.init)
            places.forEach { place in
                self?.mapView.addAnnotation(place)
            }
            
            self?.presentPlacesSheet(places: places)
        }
        
    }

}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      
        let text = textField.text ?? ""
        
        if !text.isEmpty {
            textField.resignFirstResponder()
            findNearbyPlaces(by: text)
        }
        
        return true
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        print(locations[0].coordinate.latitude)
        print(locations[0].coordinate.longitude)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    func locationManager(
        _ manager: CLLocationManager, didFailWithError error: any Error
    ) {
        print(error)
    }
}
