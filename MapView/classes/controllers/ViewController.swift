//
//  ViewController.swift
//  MapView
//
//  Created by Hung-Ming Chen on 2018/11/4.
//  Copyright © 2018年 Hung-Ming Chen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Foundation
import ARCL
import ARKit
import SceneKit

struct CurrentWeather:Decodable {
    var main:Main
}

struct Main:Decodable{
    var temp : Double
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    var myLocationManager :CLLocationManager!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var backView2: UIView!
    
    @IBOutlet weak var arBtnView: UIView!
    @IBOutlet weak var arBtn: UIButton!
    @IBOutlet weak var arView: UIView!
    @IBOutlet weak var arViewUp: NSLayoutConstraint!
    @IBOutlet weak var mapViewHeight: NSLayoutConstraint!
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet var myView: UIView!
    @IBOutlet weak var myExitBtn: UIButton!
    @IBOutlet weak var locationBtn: UIButton!
    @IBOutlet weak var mySC: UISegmentedControl!
    @IBOutlet weak var tempLab: UILabel!
    var latitude : String = ""
    var longitude : String = ""
    var mylatitude : CLLocationDegrees?
    var mylongitude : CLLocationDegrees?
    var checkBool : Bool = false
    var openSetBool : Bool = false
    var arUp : Bool = false
//    var dataArray = [AnyObject]()
    
    let sceneLocationView = SceneLocationView()
    let displayDebugging = false
    var centerMapOnUserLocation: Bool = true
    let adjustNorthByTappingSidesOfScreen = false
    var showMap = false {
        didSet {
            guard let mapView = myMapView else {
                return
            }
            mapView.isHidden = !showMap
        }
    }
    var routes: [MKRoute]?
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        didDropDown(false)
        arBtn.isEnabled = false
        navigationController?.isNavigationBarHidden = true
        backView.layer.cornerRadius = 10
        backView2.layer.cornerRadius = 10
        arView.layer.cornerRadius = 10
        arBtnView.layer.cornerRadius = 10
        backView2.isHidden = true
        locationBtn.layer.cornerRadius = 10
        myLocationManager = CLLocationManager()
        myLocationManager.delegate = self
        myLocationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        sceneLocationView.showAxesNode = true
        sceneLocationView.showFeaturePoints = displayDebugging
        sceneLocationView.frame = self.view.bounds
        arView.addSubview(sceneLocationView)
        myMapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        
        self.view.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.addSubview(myView)
        myView.translatesAutoresizingMaskIntoConstraints = false
        
        myView.heightAnchor.constraint(equalToConstant: view.bounds.height/2).isActive = true
        myView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        myView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        let c = myView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.bounds.height/2)
        c.identifier = "bottom"
        c.isActive = true
        
        myView.layer.cornerRadius = 10
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("pause")
        // Pause the view's session
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
   //     sceneLocationView.frame = arView.bounds
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        guard let touch = touches.first,
//            let view = touch.view else { return }
//
//        if myMapView == view || myMapView.recursiveSubviews().contains(view) {
//            centerMapOnUserLocation = false
//        } else {
//            let location = touch.location(in: self.view)
//
//            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
//                print("left side of the screen")
//                sceneLocationView.moveSceneHeadingAntiClockwise()
//            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
//                print("right side of the screen")
//                sceneLocationView.moveSceneHeadingClockwise()
//            } else {
//                if(arBtn.isEnabled){
//                    let image = UIImage(named: "pin")!
//                    let annotationNode = LocationAnnotationNode(location: nil, image: image)
//                    annotationNode.scaleRelativeToDistance = false
//                    annotationNode.scalingScheme = .normal
//                    sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
//                }
//            }
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            myLocationManager.requestAlwaysAuthorization()
            
            myLocationManager.startUpdatingLocation()
        case .denied:
            let alertController = UIAlertController( title: "定位權限已關閉", message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default, handler:nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        case .authorizedWhenInUse:
            myLocationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation :CLLocation = locations[0] as CLLocation
        print("\(currentLocation.coordinate.latitude)")
        print(", \(currentLocation.coordinate.longitude)")
        
        mylatitude = currentLocation.coordinate.latitude
        mylongitude = currentLocation.coordinate.longitude
        
        locationSetRegion(lat: mylatitude!, lon: mylongitude!, latDelta: 0.005, lonDelta: 0.005)
    }
    
    func locationSetRegion(lat:CLLocationDegrees, lon:CLLocationDegrees, latDelta:CLLocationDegrees, lonDelta:CLLocationDegrees){
        let currentLocationSpan:MKCoordinateSpan =
            MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let center:CLLocation = CLLocation(
            latitude: lat, longitude: lon)
        let currentRegion:MKCoordinateRegion =
            MKCoordinateRegion(center: center.coordinate, span: currentLocationSpan)
        myMapView.setRegion(currentRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        myMapView.camera.heading = newHeading.magneticHeading
        print(newHeading.magneticHeading)
        myMapView.setCamera(myMapView.camera, animated: true)
    }

    @IBAction func myExitBtnAction(_ sender: UIButton) {
        for c in view.constraints{
            if c.identifier == "bottom"{
                c.constant = view.bounds.height/2
                break
            }
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
        if checkBool{
            let height = view.bounds.height/2
            UIView.animate(withDuration: 0.5) {
                self.backView2.center.y += height
            }
            checkBool = false
        }
    }
    
    @IBAction func locationBtnAction(_ sender: UIButton) {
        for c in view.constraints{
            if c.identifier == "bottom"{
                c.constant = 0
                break
            }
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
        
        if checkBool == false{
            let height = view.bounds.height/2
            UIView.animate(withDuration: 0.5) {
                self.backView2.center.y -= height
            }
            checkBool = true
        }
    }
    
    @IBAction func showLocationAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "輸入經緯度", message: "", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        alertController.addTextField(configurationHandler: nil)
        alertController.textFields?.forEach({ (textfield) in
            textfield.keyboardType = .decimalPad
        })
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "確認", style: .default) { (action: UIAlertAction) -> Void in
            let txtlatitude = (alertController.textFields?.first)! as UITextField
            let txtlongitude = (alertController.textFields?.last)! as UITextField
            self.latitude = txtlatitude.text ?? ""
            self.longitude = txtlongitude.text ?? ""
            if self.latitude == "" || self.longitude == "" {
                self.latitude = "0"
                self.longitude = "0"
            }
            self.mylatitude = Double(self.latitude)
            self.mylongitude = Double(self.longitude)
            
            self.changeNowLocation(latitude: self.mylatitude!, longitude: self.mylongitude!)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func changeNowLocation(latitude:CLLocationDegrees, longitude:CLLocationDegrees){
        let currentLocationSpan:MKCoordinateSpan =
            MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)
        let center:CLLocation = CLLocation(
            latitude: latitude, longitude: longitude)
        let currentRegion:MKCoordinateRegion =
            MKCoordinateRegion(center: center.coordinate, span: currentLocationSpan)
        myMapView.setRegion(currentRegion, animated: true)
    }
    
    @objc func longPress(recognizer:UILongPressGestureRecognizer){
        if recognizer.state == .began{
            let annotation = myMapView.annotations
            myMapView.removeAnnotations(annotation)
            let renderer = myMapView.overlays
            myMapView.removeOverlays(renderer)
        }else if recognizer.state == .ended {
            let point = recognizer.location(in: myMapView)
            let coodinate = myMapView.convert(point, toCoordinateFrom: myMapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coodinate
            annotation.subtitle = "緯度：\(coodinate.latitude) 經度:\(coodinate.longitude)";
            myMapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func trafficSwitchAction(_ sender: UISwitch) {
        if sender.isOn{
            myMapView.showsTraffic = true
        }else{
            myMapView.showsTraffic = false
        }
    }
    
    @IBAction func mySCAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.myMapView.mapType = .standard
        case 1:
            self.myMapView.mapType = .satellite
        case 2:
            self.myMapView.mapType = .hybrid
        default:
            break
        }
    }
    // 選擇大頭針生成導航
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let latitude = view.annotation?.coordinate.latitude
        let longitude = view.annotation?.coordinate.longitude
        let alertController = UIAlertController(title: "", message: "緯度：\(latitude!)\n經度：\(longitude!)", preferredStyle: .actionSheet)
        let navigationAction = UIAlertAction(title: "導航", style: .default) { (action :UIAlertAction) -> Void in
            let startLocation = CLLocationCoordinate2D(latitude: self.mylatitude!, longitude: self.mylongitude!)
            let endLocation = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let startP = MKPlacemark(coordinate: startLocation) // 經緯度轉換地標
            let endP = MKPlacemark(coordinate: endLocation)
            let startItem = MKMapItem(placemark: startP)
            let endItem = MKMapItem(placemark: endP)
            let directionRequest = MKDirections.Request() //導航路線信息
            self.arBtn.isEnabled = true
            directionRequest.source = startItem
            directionRequest.destination = endItem
            directionRequest.transportType = .any
            let directions = MKDirections(request: directionRequest) //建立導航
            directions.calculate {
                (response, error) -> Void in
                
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                    
                    return
                }
                
                self.routes = response.routes
                
                let route = response.routes[0]
                print(route.steps)
                self.myMapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)                     // 添加覆蓋物路線
                
                let rect = route.polyline.boundingMapRect          // 取得範圍
                self.myMapView.setRegion(MKCoordinateRegion(rect), animated: true)
            }
        }
        let deleteAction = UIAlertAction(title: "刪除", style: .default) { (actaion :UIAlertAction) -> Void in
            let annotation = self.myMapView.annotations
            self.myMapView.removeAnnotations(annotation)
            let renderer = self.myMapView.overlays
            self.myMapView.removeOverlays(renderer)
            self.arBtn.isEnabled = false
            self.didDropDown(false)
            self.sceneLocationView.removeRoutes(routes: self.routes!)
            self.sceneLocationView.pause()
            self.routes = []
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(navigationAction)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    //導航引導線
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {                                        // 覆蓋物要顯示的東西
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        renderer.lineWidth = 6.0
        
        return renderer
    }
    
    // 溫度API
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let myCenter:CLLocationCoordinate2D = myMapView.region.center
//        var myStr : String = "https://api.openweathermap.org/data/2.5/weather?lat="
//        myStr += "\(myCenter.latitude)&lon="
//        myStr += "\(myCenter.longitude)&appid=2ee0974e6cceacf8141f7cf5ef514bff&units=metric"
////        print(myStr)
//
////        let headers = [
////            "cache-control": "no-cache",
////            "Postman-Token": "601d464a-e16e-4c3d-9bc8-f449b8400e78"
////        ]
//
//        var request = URLRequest(url: NSURL(string: myStr)! as URL)
//        request.httpMethod = "GET"
////        request.allHTTPHeaderFields = headers
//
//        let urlSession = URLSession.shared
//
//
//        urlSession.dataTask(with: request) { (data, response, error) in
//            if let error = error{
//                print(error)
//            }else if let response = response as? HTTPURLResponse,let data = data{
//                let decoder = JSONDecoder()
//                if let object = try? decoder.decode(CurrentWeather.self, from: data){
//                    print(object.main.temp)
//                    DispatchQueue.main.async {
//                        self.backView2.isHidden = false
//                        self.tempLab.text = "\(Int(object.main.temp))˚"
//                    }
//                }
//            }
//        }.resume()
//    }
    
    // AR Btn
    @IBAction func upView(_ sender: Any) {
        if(arUp == false){
            didDropDown(true)
            sceneLocationView.run()
            addSceneModels()
//            myLocationManager.startUpdatingHeading()
            arUp = true
        }else{
            didDropDown(false)
            sceneLocationView.removeRoutes(routes: routes!)
            sceneLocationView.pause()
//            myLocationManager.stopUpdatingHeading()
            arUp = false
        }
        
    }
    // 地圖約束調整
    func didDropDown(_ bool: Bool) {
        UIView.animate(withDuration: 0.5) {
            if bool {
                self.myMapView.layer.borderWidth = 3
                self.myMapView.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                self.myMapView.alpha = 0.8
                self.mapViewHeight.constant = self.arView.bounds.width-self.arView.bounds.height
                self.arViewUp.constant = (self.arView.bounds.height * 3 / 5)
                self.myMapView.layer.cornerRadius = self.myMapView.bounds.width / 2
                self.locationSetRegion(lat: self.mylatitude!, lon: self.mylongitude!, latDelta: 0.001, lonDelta: 0.001)
            } else {
                self.myMapView.layer.borderWidth = 0
                self.myMapView.layer.borderColor = nil
                self.myMapView.layer.shadowRadius = 0
                self.myMapView.alpha = 1
                self.mapViewHeight.constant = 0
                self.arViewUp.constant = 0
                self.myMapView.layer.cornerRadius = 0
            }
            self.view.layoutIfNeeded()
        }
    }
    
   
}

extension UIView {
    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews
        
        subviews.forEach { recursiveSubviews.append(contentsOf: $0.recursiveSubviews()) }
        
        return recursiveSubviews
    }
}

// AR Line
extension ViewController {
    
    func addSceneModels() {
        // 1. Don't try to add the models to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addSceneModels()
            }
            return
        }
        
        let box = SCNBox(width: 1, height: 0.2, length: 5, chamferRadius: 0.25)
        box.firstMaterial?.diffuse.contents = UIColor.gray.withAlphaComponent(0.5)
        
        // 2. If there is a route, show that
        if let routes = routes {
            sceneLocationView.removeAllNodes()
            sceneLocationView.addRoutes(routes: routes) { distance -> SCNBox in
                let box = SCNBox(width: 1.75, height: 0.5, length: distance, chamferRadius: 0.25)
                
                //                // Option 1: An absolutely terrible box material set (that demonstrates what you can do):
                //                box.materials = ["box0", "box1", "box2", "box3", "box4", "box5"].map {
                //                    let material = SCNMaterial()
                //                    material.diffuse.contents = UIImage(named: $0)
                //                    return material
                //                }
                
                // Option 2: Something more typical
                box.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.7)
                return box
            }
        } else {
            // 3. If not, then show the
            buildDemoData().forEach {
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0)
            }
        }
    }
    
    
    
    //  Nodes
    func buildDemoData() -> [LocationAnnotationNode] {
        var nodes: [LocationAnnotationNode] = []
        
//        let spaceNeedle = buildNode(latitude: 47.6205, longitude: -122.3493, altitude: 225, imageName: "pin")
//        nodes.append(spaceNeedle)
//
//        let empireStateBuilding = buildNode(latitude: 40.7484, longitude: -73.9857, altitude: 14.3, imageName: "pin")
//        nodes.append(empireStateBuilding)
//
//        let canaryWharf = buildNode(latitude: 51.504607, longitude: -0.019592, altitude: 236, imageName: "pin")
//        nodes.append(canaryWharf)
//
//        let applePark = buildViewNode(latitude: 37.334807, longitude: -122.009076, altitude: 100, text: "Apple ParApple Parkk")
//        nodes.append(applePark)
        
        return nodes
    }
    
    @objc
    func updateUserLocation() {
        guard let currentLocation = sceneLocationView.sceneLocationManager.currentLocation else {
            return
        }

        DispatchQueue.main.async { [weak self ] in
            guard let self = self else {
                return
            }

            if self.userAnnotation == nil {
                self.userAnnotation = MKPointAnnotation()
                self.myMapView.addAnnotation(self.userAnnotation!)
            }

            UIView.animate(withDuration: 0.5, delay: 0, options: .allowUserInteraction, animations: {
                self.userAnnotation?.coordinate = currentLocation.coordinate
            }, completion: nil)

            if self.centerMapOnUserLocation {
                UIView.animate(withDuration: 0.45,
                               delay: 0,
                               options: .allowUserInteraction,
                               animations: {
                                self.myMapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                }, completion: { _ in
                    self.myMapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                })
            }

            if self.displayDebugging {
                if let bestLocationEstimate = self.sceneLocationView.sceneLocationManager.bestLocationEstimate {
                    if self.locationEstimateAnnotation == nil {
                        self.locationEstimateAnnotation = MKPointAnnotation()
                        self.myMapView.addAnnotation(self.locationEstimateAnnotation!)
                    }
                    self.locationEstimateAnnotation?.coordinate = bestLocationEstimate.location.coordinate
                } else if self.locationEstimateAnnotation != nil {
                    self.myMapView.removeAnnotation(self.locationEstimateAnnotation!)
                    self.locationEstimateAnnotation = nil
                }
            }
        }
    }
//
//    func buildNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
//                   altitude: CLLocationDistance, imageName: String) -> LocationAnnotationNode {
//        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        let location = CLLocation(coordinate: coordinate, altitude: altitude)
//        let image = UIImage(named: imageName)!
//        return LocationAnnotationNode(location: location, image: image)
//    }
//
//    func buildViewNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
//                       altitude: CLLocationDistance, text: String) -> LocationAnnotationNode {
//        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        let location = CLLocation(coordinate: coordinate, altitude: altitude)
//        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//        label.text = text
//        label.backgroundColor = .green
//        label.textAlignment = .center
//        return LocationAnnotationNode(location: location, view: label)
//    }
}

