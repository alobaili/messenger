//
//  LocationPickerViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 08/08/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var isPicking = true
    
    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.selectedCoordinate = coordinate
        isPicking = false
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        mapView.isRotateEnabled = false

        layoutViews()
        
        if isPicking {
            title = "Pick A Location"
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            mapView.addGestureRecognizer(tapGestureRecognizer)
        } else {
            guard let selectedCoordinate = selectedCoordinate else { return }
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: selectedCoordinate.latitude, longitude: selectedCoordinate.longitude)
            
            geocoder.reverseGeocodeLocation(location) { [weak self] (placeMarks, error) in
                if let placeMark = placeMarks?.first {
                    self?.title = placeMark.name
                }
            }
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(cancelButtonTapped))
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedCoordinate
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegion(center: selectedCoordinate, latitudinalMeters: 15000, longitudinalMeters: 15000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func layoutViews() {
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func sendButtonTapped() {
        guard let selectedCoordinate = selectedCoordinate else { return }
        
        completion?(selectedCoordinate)
        
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func didTapMap(_ gesture: UITapGestureRecognizer) {
        // Remove any existing annotations
        selectedCoordinate = nil
        mapView.removeAnnotations(mapView.annotations)
        
        // Get the new coordinate
        let locationInView = gesture.location(in: mapView)
        let selectedCoordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
        self.selectedCoordinate = selectedCoordinate
        
        // Add a new annotation on that coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedCoordinate
        mapView.addAnnotation(annotation)
    }
    
}
