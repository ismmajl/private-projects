//
//  CongratulationsController.swift
//  upbike

import UIKit
import MapKit
import AdvancedPageControl

class CongratulationsController: ViewController {
    
    @IBOutlet weak var logoImgView: UIImageView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var nameHolder: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var rideTitleLabel: UILabel!
    @IBOutlet weak var caloriesTopLabel: UILabel!
    @IBOutlet weak var caloriesBottomLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var avgSpeedLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var pageControl: AdvancedPageControlView!
    @IBOutlet weak var alertBlurView: UIVisualEffectView!
    @IBOutlet weak var mapView: MKMapView!
    
    private var ride: Ride!
    private var isSharing = false
    private var polyLine = MKPolyline()
    private var polyLineCoordinates: [CLLocationCoordinate2D] = []
    
    private var images: [UIImage] = [] {
        didSet {
            mapView.isHidden = !images.isEmpty
            collectionView.isHidden = images.isEmpty
        }
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initCollectionView()
        setValues()
        setPageControl()
        setMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton = true
    }
    
    //MARK: - Set Values
    private func setValues() {
        self.title = isSharing ? (ride.title.isEmpty ? ride.mode.name : ride.title) : "Congratulations.label.Title".localized()
        let title = ride.title.isEmpty ? ride.mode.name : ride.title
        rideTitleLabel.text = title
        nameHolder.isHidden = title.isEmpty
        caloriesTopLabel.set(title: String(ride.caloriesC), with: .mainFontSize, subTitle: "", with: .mainUnitFontSize)
        caloriesBottomLabel.set(title: String(ride.caloriesC), with: .mainFontSize, subTitle: "", with: .mainUnitFontSize)
        distanceLabel.set(title: Utils.metersToDistance(meters: ride.distanceC), with: .mainFontSize, subTitle: Preferences.distanceUnit.lowercased(), with: .mainUnitFontSize)
        timeLabel.set(title: Utils.secondsToHoursMinutesSeconds(seconds: ride.durationC), with: .mainFontSize, subTitle: "", with: .mainUnitFontSize)
        maxSpeedLabel.set(title: Utils.mpsToSpeed(ms: ride.maxSpeedC).0, with: .mainFontSize, subTitle: Utils.speedUnit, with: .mainUnitFontSize)
        avgSpeedLabel.set(title: Utils.mpsToSpeed(ms: ride.averageSpeedC).0, with: .mainFontSize, subTitle: Utils.speedUnit, with: .mainUnitFontSize)
        
        alertBlurView.isHidden = isSharing
        nameHolder.isHidden = isSharing
        //rideInfo = Array(ride.rideInfos)
        
        mapView.isHidden = !images.isEmpty
        logoImgView.isHidden = !images.isEmpty
        collectionView.isHidden = images.isEmpty
        
        //get images
        let paths = Array(ride.photos)
        getImageFromDocumentDirectory(paths: paths)
    }
    
    //MARK: - Functions
    private func setPageControl() {
        pageControl.drawer = ExtendedDotDrawer(
            numberOfPages: images.count,
            height: 5,
            width: 5,
            space: 5.0,
            raduis: 5,
            indicatorColor: UIColor.WhiteColor,
            dotsColor: UIColor.WhiteColor,
            isBordered: false,
            borderWidth: 0.0,
            indicatorBorderColor: .clear,
            indicatorBorderWidth: 0.0)
    }
    
    private func getImageFromDocumentDirectory(paths: [String]) {
        let fileManager = FileManager.default
        for path in paths {
            if fileManager.fileExists(atPath: path) {
                if let image = UIImage(contentsOfFile: path) {
                    images.append(image)
                }
            } else {
                print("Error GetImages: No Image was found")
            }
        }
        collectionView.reloadData()
    }
    
    private func share(image: UIImage) {
        let text = "Sharing.action.Title".localized()
        let vc = UIActivityViewController(activityItems: [text, image], applicationActivities: [])
        
        if let popoverController = vc.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = self.view.bounds
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    //MARK: - IBActions
    @IBAction func closeAlertButtonPressed(_ sender: UIButton) {
        alertBlurView.isHidden = true
    }
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        guard let image = UIImage(snapshotOf: mainStackView) else { return }
        share(image: image)
    }
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.navigationController?.hideModal()
    }
}

//MARK: - Map View
extension CongratulationsController: MKMapViewDelegate  {
    
    private func setMap() {
        mapView.delegate = self
        mapView.isScrollEnabled = false
        
        ride.rideInfos.forEach { info in
            polyLineCoordinates.append(CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude))
        }
        polyLine = MKPolyline(coordinates: polyLineCoordinates, count: polyLineCoordinates.count)
        mapView.addOverlay(polyLine)
        
        mapView.setRegion(MKCoordinateRegion(center: getLocationSpan().0, span: getLocationSpan().1), animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let routePolyline = overlay as? MKPolyline else { return MKOverlayRenderer() }
        let renderer = MKPolylineRenderer(polyline: routePolyline)
        renderer.strokeColor = UIColor.TintColor
        renderer.lineWidth = 3
        return renderer
    }
    
    private func getLocationSpan() -> ( CLLocationCoordinate2D, MKCoordinateSpan) {
        guard let firstCoordinate = polyLineCoordinates.first else { return (CLLocationCoordinate2D(), MKCoordinateSpan()) }
        let firstLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        var maxDistance: Double = 0.0
        var maxCoordinate = CLLocationCoordinate2D()
        
        for coordinate in polyLineCoordinates {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distanceInMeters = firstLocation.distance(from: location)
            if distanceInMeters > maxDistance {
                maxDistance = distanceInMeters
                maxCoordinate = coordinate
            }
        }
        
        guard maxDistance > 0 else {
            let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            return (firstCoordinate, coordinateSpan)
        }
        //one degree in cllocation is 111km
        let coordinatePreDelta = maxDistance / (111 * 1000)
        
        //add some margins
        let coordinateDelta = coordinatePreDelta < 0.001 ? 0.001 : coordinatePreDelta * 1.2
        let coordinateSpan = MKCoordinateSpan(latitudeDelta: coordinateDelta, longitudeDelta: coordinateDelta)
        let middleCoordinate = CLLocationCoordinate2D(latitude: (firstCoordinate.latitude + maxCoordinate.latitude) / 2, longitude: (firstCoordinate.longitude + maxCoordinate.longitude) / 2)
        
        return (middleCoordinate, coordinateSpan)
    }
}


//MARK: - CollectionView Delegates
extension CongratulationsController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private func initCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CongratulationImageCCell.self)
        //collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(CongratulationImageCCell.self, for: indexPath)
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.01
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.01
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        pageControl.setPage(indexPath.item)
    }
}

extension CongratulationsController {
    static func create(ride: Ride, isSharing: Bool = false) -> CongratulationsController {
        let controller = UIStoryboard.main.instantiate(CongratulationsController.self)
        controller.ride = ride
        controller.isSharing = isSharing
        return controller
    }
}
