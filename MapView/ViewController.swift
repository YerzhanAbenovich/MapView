//
//  ViewController.swift
//  MapView
//
//  Created by Yerzhan Parimbay on 30.08.2025.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    var followMe = false
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        let mapDragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didDragMap))
        
        mapDragRecognizer.delegate = self
        
        mapView.addGestureRecognizer(mapDragRecognizer)
        
        let lat:CLLocationDegrees = 37.957666//43. 2374454
        let long:CLLocationDegrees = -122.0323133//76.909891
        
        // Создаем координта передавая долготу и широту
        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        
        // Создаем метку на карте
        let anotation = MKPointAnnotation()
        
        // Задаем коортинаты метке
        anotation.coordinate = location
        // Задаем название метке
        anotation.title = "Title"
        // Задаем описание метк
        anotation.subtitle = "subtitle"
        
        // Добавляем метку на карту
        mapView.addAnnotation (anotation)
        // Метка на карте
        // Настраиваем долгое нажатие - добавляем новые метки на карту
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector (self.longPressAction))
        // минимально 2 секунды
        longPress.minimumPressDuration = 2
        mapView.addGestureRecognizer(longPress)
        
        mapView.delegate = self
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        userLocation = locations[0]
        print(userLocation)
        
        
        if followMe{
            let latDelta: CLLocationDegrees = 0.01
            let longDelta: CLLocationDegrees = 0.01
            
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            
            let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
            
            mapView.setRegion(region, animated: true)
            
            
        }
    }
    
    @IBAction func showMyLocation(_ sender: Any) {
        followMe = true
    }
    
    @objc func didDragMap (gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizer.State.began) {
            
            followMe = false
            
            print("Map drag changed!")
        }
    }
    
    @objc func longPressAction (gestureRecognizer: UIGestureRecognizer) {
        
        print ( "gestureRecognizer")
        
        // Получаем точку нажатия на экране
        let touchPoint = gestureRecognizer.location(in: mapView)
        
        // Конвертируем точку нажатия на экране в координаты пользователя
        let newCoor: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        // Создаем метку на карте
        let anotation = MKPointAnnotation ( )
        anotation.coordinate = newCoor
        
        anotation.title = "Title"
        anotation.subtitle = "subtitle"
        
        mapView.addAnnotation(anotation)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print(view.annotation?.title)
        
        // Получаем координаты метки
        let location:CLLocation = CLLocation (latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        
        // Считаем растояние до метки от нашего пользователя
        let meters:CLLocationDistance = location.distance (from: userLocation)
        distanceLabel.text = String (format: "Distance: %.2f m", meters)
        
        // Routing - построение маршрута
        // 1 Координаты начальной точки А и точки В
        let sourceLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let destinationLocation = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        
        // 2 упаковка B Placemark
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
        
        // 3 упаковка B MapItem
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        // 4 Запрос на построение маршрута
        let directionRequest = MKDirections.Request ()
        
        // указываем точку А, то есть нашего пользователя
        directionRequest.source = sourceMapItem
        
        // указываем точку В, то есть метку на карте
        directionRequest.destination = destinationMapItem
        
        // выбираем на чем будем ехать - на машине
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections (request: directionRequest)
        
        // 5 Запускаем просчет маршрута
        directions.calculate {
            (response, error) -> Void in
            
            // Если будет ошибка с маршрутом
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
                
                // Берем первый машрут
                let route = response.routes[0]
                // Удалить все существующие маршруты
                self.mapView.removeOverlays(self.mapView.overlays)
                // Рисуем на карте линию маршрута (polyline)
                self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
                
                // Приближаем карту с анимацией в регион всего маршрута
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Настраиваем линию
            let renderer = MKPolylineRenderer(overlay: overlay)
            // Цвет красный
            renderer.strokeColor = UIColor.red
            // Ширина линии
            renderer.lineWidth = 2.0
            
            return renderer
        }
        
    
}
