//
//  SaveAndRideDetailsController.swift
//  combike


import UIKit
import MapKit
import GPXKit
import Photos
import CoreLocation

class SaveAndRideDetailsController: ViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var feelSlider: CustomSlider!
    @IBOutlet weak var sliderGestureView: UIView!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var avgSpeedLabel: UILabel!
    @IBOutlet weak var minAltLabel: UILabel!
    @IBOutlet weak var maxAltLabel: UILabel!
    
    @IBOutlet weak var titleHolderView: UIView!
    @IBOutlet weak var descHolderView: UIView!
    @IBOutlet weak var rideFeelHolderView: UIView!
    @IBOutlet weak var descCompletedHolderView: UIView!
    @IBOutlet weak var rideFeelCompletedHolderView: UIView!
    @IBOutlet weak var descCompletedLabel: UILabel!
    @IBOutlet weak var rideFeelCompletedLabel: UILabel!
    @IBOutlet weak var saveDetailsButton: UIButton!
    
    @IBOutlet weak var topCaloriesHolder: UIView!
    @IBOutlet weak var topCaloriesLabel: UILabel!
    @IBOutlet weak var bottomCaloriesHolder: UIView!
    @IBOutlet weak var bottomCaloriesLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noDataMapView: UIView!
    
    @IBOutlet weak var startEndTimeHolderView: UIView!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    
    @IBOutlet weak var rideChartHolderView: UIView!
    
    @IBOutlet weak var speedHistoryHolderView: UIView!
    @IBOutlet weak var speedHistoryView: UIView!
    @IBOutlet weak var speedHistoryBlurHolder: UIView!
    @IBOutlet weak var noDataSpeedHistoryLabel: UILabel!
    
    @IBOutlet weak var altitudeHistoryHolderView: UIView!
    @IBOutlet weak var altitudeHistoryView: UIView!
    @IBOutlet weak var altitudeHistoryBlurHolder: UIView!
    @IBOutlet weak var noDataAltitudeHistoryLabel: UILabel!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var photoCollectionViewHolder: UIView!
    @IBOutlet weak var photoCompletedCollectionView: UICollectionView!
    @IBOutlet weak var photoCompletedCollectionViewHolder: UIView!
    
    @IBOutlet weak var emptyRideCollectionView: UICollectionView!
    @IBOutlet weak var rideCollectionView: UICollectionView!
    
    @IBOutlet weak var lockedContinueButton: UIButton!
    @IBOutlet weak var exportGPXButton: UIButton!
    
    
    //MARK: - Vars
    private var ride: Ride!
    private var rideInfo: [RideInfo] = []
    private var images: [UIImage] = []
    
    private var polyLine = MKPolyline()
    private var polyLineCoordinates: [CLLocationCoordinate2D] = []
    private var count: Int = 0
    
    //GPX, temporary file
    fileprivate var tempFilePath: URL = {
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ride").appendingPathExtension("gpx").absoluteString
        if FileManager.default.fileExists(atPath: tempPath) {
            try? FileManager.default.removeItem(atPath: tempPath)
        }
        return URL(string: tempPath)!
    }()
    
    //charts
    private var rideInfoAverage: [RideInfo] = []
    
    //graphs
    private var fakeGraph: [Double] = [2, 3, 10, 50, 20, 60, 80, 12, 34, 56, 22, 12, 6, 34, 72, 48, 20]
    // LinePlot identifiers should be unique for each plot.
    private let speedLinePlot = LinePlot(identifier: "paceLine")
    private let altitudeLinePlot = LinePlot(identifier: "altitudeLine")
    
    private var modifiedAverageSpeed: [Double] = []
    private var modifiedAverageAltitude: [Int] = []
    private var modifiedAverageDate: [Date] = []
    
    private lazy var speedGraphView: ScrollableGraphView = {
        let graph = ScrollableGraphView()
        
        let numberOfElements = Preferences.isProUser ? CGFloat(modifiedAverageSpeed.count) : CGFloat(fakeGraph.count)
        let dataSparcity = Preferences.isProUser ? (modifiedAverageSpeed.count >= 5 ? Int(modifiedAverageSpeed.count / 5) : modifiedAverageSpeed.count) : fakeGraph.count
        
        graph.bounds = speedHistoryView.bounds
        graph.dataSource = self
        graph.bounces = false
        graph.shouldAdaptRange = true
        graph.shouldAnimateOnStartup = true
        graph.backgroundFillColor = .clear
        graph.tintColor = .BlackColor
        graph.dataPointSpacing = (graph.bounds.width - 60) / numberOfElements
        graph.rightmostPointPadding = 0
        //graph.leftmostPointPadding = 20
        //graph.topMargin = 200
        //graph.direction = .leftToRight
        
        speedLinePlot.adaptAnimationType = .elastic
        speedLinePlot.shouldFill = true
        speedLinePlot.fillType = .gradient
        speedLinePlot.fillGradientStartColor = .TintColor
        speedLinePlot.fillGradientEndColor = .WhiteColor
        speedLinePlot.fillGradientType = .radial
        speedLinePlot.lineStyle = .smooth
        speedLinePlot.lineColor = .TintColor
        graph.addPlot(plot: speedLinePlot)
        
        let referenceLines = ReferenceLines()
        referenceLines.dataPointLabelsSparsity = dataSparcity
        referenceLines.referenceLineColor = .LightGrayMonoColor
        referenceLines.dataPointLabelColor = .DarkTextColor
        referenceLines.referenceLineLabelColor = .DarkTextColor
        referenceLines.referenceLineUnits = Utils.speedUnit
        graph.addReferenceLines(referenceLines: referenceLines)
        
        return graph
    }()
    
    private lazy var altitudeGraphView: ScrollableGraphView = {
        let graph = ScrollableGraphView()
        
        let numberOfElements = Preferences.isProUser ? CGFloat(modifiedAverageAltitude.count) : CGFloat(fakeGraph.count)
        let dataSparcity = Preferences.isProUser ? (modifiedAverageAltitude.count >= 5 ? Int(modifiedAverageAltitude.count / 5) : rideInfo.count) : fakeGraph.count
        
        graph.bounds = altitudeHistoryView.bounds
        graph.dataSource = self
        
        graph.bounces = false
        graph.shouldAdaptRange = true
        graph.shouldAnimateOnStartup = true
        graph.backgroundFillColor = .clear
        graph.tintColor = .BlackColor
        graph.dataPointSpacing = (graph.bounds.width - 60) / numberOfElements
        graph.rightmostPointPadding = 0
        
        altitudeLinePlot.adaptAnimationType = .elastic
        altitudeLinePlot.shouldFill = true
        altitudeLinePlot.fillType = .gradient
        altitudeLinePlot.fillGradientStartColor = .TintColor
        altitudeLinePlot.fillGradientEndColor = .WhiteColor
        altitudeLinePlot.fillGradientType = .radial
        altitudeLinePlot.lineStyle = .smooth
        altitudeLinePlot.lineColor = .TintColor
        graph.addPlot(plot: altitudeLinePlot)
        
        let referenceLines = ReferenceLines()
        referenceLines.dataPointLabelsSparsity = dataSparcity
        referenceLines.referenceLineColor = .LightGrayMonoColor
        referenceLines.dataPointLabelColor = .DarkTextColor
        referenceLines.referenceLineLabelColor = .DarkTextColor
        referenceLines.referenceLineUnits = Utils.altitudeUnit
        graph.addReferenceLines(referenceLines: referenceLines)
        
        return graph
    }()
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commonInit()
        setValues()
        setMap()
        setGraphs()
        setObservers()
    }
    
    //MARK: - Functions
    
    private func setObservers() {
        Bird.listen(observer: self, name: .rideDetails, selector: #selector(setImage))
    }
    
    @objc
    func setImage(_ notification: Notification) {
        guard let item = notification.object as? UIImage else { return }
        images.append(item)
        photoCollectionView.reloadData()
        photoCompletedCollectionView.reloadData()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                speedLinePlot.fillGradientStartColor = .TintColor
                speedLinePlot.fillGradientEndColor = .WhiteColor
                speedGraphView.addPlot(plot: speedLinePlot)
                altitudeLinePlot.fillGradientStartColor = .TintColor
                altitudeLinePlot.fillGradientEndColor = .WhiteColor
                altitudeGraphView.addPlot(plot: altitudeLinePlot)
            }
        }
    }
    
    private func commonInit() {
        feelSlider.isContinuous = true
        mapView.delegate = self
        mapView.isScrollEnabled = false
        initCollectionView()
        
        if ride.isCompleted {
            setupGPX()
        }
    }
    
    private func setGraphs() {
        if (ride.maxSpeedC > 0 && ride.version != .v1) || !Preferences.isProUser {
            speedHistoryView.addSubview(speedGraphView)
            speedGraphView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                speedGraphView.topAnchor.constraint(equalTo: speedHistoryView.topAnchor),
                speedGraphView.bottomAnchor.constraint(equalTo: speedHistoryView.bottomAnchor),
                speedGraphView.leadingAnchor.constraint(equalTo: speedHistoryView.leadingAnchor),
                speedGraphView.trailingAnchor.constraint(equalTo: speedHistoryView.trailingAnchor)
            ])
        }
        if (ride.maxAltitudeC > 0 && ride.version != .v1) || !Preferences.isProUser {
            altitudeHistoryView.addSubview(altitudeGraphView)
            altitudeGraphView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                altitudeGraphView.topAnchor.constraint(equalTo: altitudeHistoryView.topAnchor),
                altitudeGraphView.bottomAnchor.constraint(equalTo: altitudeHistoryView.bottomAnchor),
                altitudeGraphView.leadingAnchor.constraint(equalTo: altitudeHistoryView.leadingAnchor),
                altitudeGraphView.trailingAnchor.constraint(equalTo: altitudeHistoryView.trailingAnchor)
            ])
        }
    }
    
    
    //MARK: - Set Values
    private func setValues() {
        let titleLabel = ride.isCompleted ? (ride.title.isEmpty ? ride.mode.name.uppercased() : ride.title) : ride.mode.name.uppercased()
        self.navigationItem.setNavbar(title: titleLabel, subTitle: ride.subtitle)
        navigationController?.navigationBar.setNeedsLayout()
        
        titleHolderView.isHidden = ride.isCompleted
        descHolderView.isHidden = ride.isCompleted
        rideFeelHolderView.isHidden = ride.isCompleted
        descCompletedHolderView.isHidden = ride.isCompleted ? ride.desc.isEmpty : true
        rideFeelCompletedHolderView.isHidden = !ride.isCompleted
        
        topCaloriesLabel.set(title: String(ride.caloriesC), with: .mainFontSize, subTitle: "", with: .mainUnitFontSize)
        bottomCaloriesLabel.set(title: String(ride.caloriesC), with: .mainFontSize, subTitle: "", with: .mainUnitFontSize)
        distanceLabel.set(title: Utils.metersToDistance(meters: ride.distanceC), with: .mainFontSize, subTitle: Preferences.distanceUnit.lowercased(), with: .mainUnitFontSize)
        timeLabel.set(title: Utils.secondsToHoursMinutesSeconds(seconds: ride.durationC), with: .mainFontSize, subTitle: "", with: .mainUnitFontSize)
        maxSpeedLabel.set(title: Utils.mpsToSpeed(ms: ride.maxSpeedC).0, with: .mainFontSize, subTitle: Utils.speedUnit, with: .mainUnitFontSize)
        avgSpeedLabel.set(title: Utils.mpsToSpeed(ms: ride.averageSpeedC).0, with: .mainFontSize, subTitle: Utils.speedUnit, with: .mainUnitFontSize)
        minAltLabel.set(title: Utils.calculateAltitude(altitude: ride.minAltitudeC), with: .mainFontSize, subTitle: Utils.altitudeUnit, with: .mainUnitFontSize)
        maxAltLabel.set(title: Utils.calculateAltitude(altitude: ride.maxAltitudeC), with: .mainFontSize, subTitle: Utils.altitudeUnit, with: .mainUnitFontSize)
        
        count = Int((UIScreen.main.bounds.width - 40) / 5)
        rideInfo = Array(ride.rideInfos)
        
        noDataMapView.isHidden = ride.version != .v1
        noDataSpeedHistoryLabel.isHidden = Preferences.isProUser ? (ride.version != .v1 ? ride.maxSpeedC > 0 : false) : true
        noDataAltitudeHistoryLabel.isHidden = Preferences.isProUser ? (ride.version != .v1 ? ride.maxAltitudeC > 0 : false) : true
        
        photoCollectionViewHolder.isHidden = ride.isCompleted
        photoCompletedCollectionViewHolder.isHidden = !ride.isCompleted
            
        //get averages
        if rideInfo.count != 0 {
            let sampleRate: Double = Double(rideInfo.count) / Double(count)
            for i in stride(from: sampleRate, to: Double(rideInfo.count), by: sampleRate) {
                rideInfoAverage.append(rideInfo[Int(i)])
            }
        }
        
        titleTextField.text = ride.title
        titleTextField.addTarget(self, action:  #selector(editingChanged(sender:)), for: .editingChanged)
        descTextView.text = ride.desc
        descTextView.delegate = self
        descCompletedLabel.text = ride.desc
        
        rideChartHolderView.isHidden = true
        speedHistoryBlurHolder.isHidden = Preferences.isProUser
        altitudeHistoryBlurHolder.isHidden = Preferences.isProUser
        
        startTimeLabel.text = Utils.getHoursMinutes(date: ride.startDateC)
        endTimeLabel.text = Utils.getHoursMinutes(date: ride.endDateC)
        
        saveDetailsButton.isHidden = ride.isCompleted
        exportGPXButton.isHidden = !Preferences.isProUser
        lockedContinueButton.isHidden = Preferences.isProUser
        lockedContinueButton.setTitleColor(.DarkTextColor.withAlphaComponent(0.4), for: .normal)
        lockedContinueButton.backgroundColor = .TintColor.withAlphaComponent(0.22)
        
        feelSlider.setValue(ride.isCompleted ? Float(ride.rideFeel) : 0.5, animated: true)
        rideFeelCompletedLabel.text = ride.rideFeel == 0 ? "RideDetails.label.Easy".localized() : (ride.rideFeel == 1 ? "RideDetails.label.Exhausting".localized() : "RideDetails.label.Moderate".localized())
        
        //get images
        if ride.isCompleted { getRideImages() }
        
        //data = rideInfo.map({$0.speed})
        rideCollectionView.reloadData()
        
        photoCollectionView.reloadData()
        photoCompletedCollectionView.reloadData()
        
        //Calculate info points
        createAverageInfos()
    }
    
    private func createAverageInfos() {
        let groupingSize = Int(floor(Double(rideInfo.count) / 60.0))
        let remainder = rideInfo.count / 60
        
        //Calculate Speeds
        let speeds = rideInfo.map {$0.speed}
        if rideInfo.count > 60 {
            let groupedSpeeds = speeds.chunked(into: groupingSize)
            modifiedAverageSpeed = groupedSpeeds.map {Double($0.reduce(0, +)) / (Double($0.count) != 0 ? Double($0.count) : 1)}
            
            for i in (rideInfo.count - remainder)..<rideInfo.count {
                modifiedAverageSpeed.append(rideInfo[i].speed)
            }
        } else {
            modifiedAverageSpeed = speeds
        }
        
        
        //Calculate Altitudes
        let altitudes = rideInfo.map {$0.altitude}
        if rideInfo.count > 60 {
            let groupedAltitudes = altitudes.chunked(into: groupingSize)
            modifiedAverageAltitude = groupedAltitudes.map {Int(Double($0.reduce(0, +)) / (Double($0.count) != 0 ? Double($0.count) : 1))}
            
            for i in (rideInfo.count - remainder)..<rideInfo.count {
                modifiedAverageAltitude.append(rideInfo[i].altitude)
            }
        } else {
            modifiedAverageAltitude = altitudes
        }
        
        
        //Calculate time
        let dates = rideInfo.map {$0.date}
        if rideInfo.count > 60 {
            let groupedDate = dates.chunked(into: groupingSize)
            modifiedAverageDate = groupedDate.compactMap {$0.middle}
            
            for i in (rideInfo.count - remainder)..<rideInfo.count {
                modifiedAverageDate.append(rideInfo[i].date)
            }
        } else {
            modifiedAverageDate = dates
        }
        
    }
    
    //MARK: - Set Map
    private func setMap() {
        ride.rideInfos.forEach { info in
            if info.latitude != 0 && info.longitude != 0 {
                polyLineCoordinates.append(CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude))
            }
        }
        polyLine = MKPolyline(coordinates: polyLineCoordinates, count: polyLineCoordinates.count)
        mapView.addOverlay(polyLine)
        
        mapView.setRegion(MKCoordinateRegion(center: getLocationSpan().0, span: getLocationSpan().1), animated: true)
    }
    
    private func getLocationSpan() -> ( CLLocationCoordinate2D, MKCoordinateSpan) {
        var checkedPolyLineCoordinates:  [CLLocationCoordinate2D] = []
        
        for coordinate in polyLineCoordinates {
            if coordinate.latitude != 0 && coordinate.longitude != 0 {
                checkedPolyLineCoordinates.append(coordinate)
            }
        }
        
        guard let firstCoordinate = checkedPolyLineCoordinates.first else { return (CLLocationCoordinate2D(), MKCoordinateSpan()) }
        let firstLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
        var maxDistance: Double = 0.0
        var maxCoordinate = CLLocationCoordinate2D()
        
        for coordinate in checkedPolyLineCoordinates {
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
    
    //MARK: - Setup GPX
    private func setupGPX() {
        var trackPoints: [TrackPoint] = []
        for info in rideInfo {
            trackPoints.append(TrackPoint(coordinate: Coordinate(latitude: info.latitude, longitude: info.longitude), date: info.date))
        }
        let track = GPXTrack(date: ride.startDateC, title: ride.title, description: ride.desc, trackPoints: trackPoints, keywords: [ride.modeType, ride.title])
        let exporter = GPXExporter(track: track, shouldExportDate: false)
        
        do {
            //create temporary gpx file to share it.
            try exporter.xmlString.write(to: tempFilePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("GPX couldnt be saved in the file")
        }
    }
    
    private func shareGPX() {
        let vc = UIActivityViewController(activityItems: [tempFilePath], applicationActivities: [])
        if let popoverController = vc.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = self.view.bounds
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    //MARK: - Finish Ride
    private func finishRide() {
        let rides : [Ride] = Ride.all().toArray()
        guard let ride = Array(rides.filter({$0.id == ride.id})).first else { return }
        
        if ride.isCompleted {
            StorageManager.deleteAllDirectories(paths: Array(ride.photos))
            if !images.isEmpty {
                for image in images {
                    ride.photos.insert(StorageManager.saveImageDocumentDirectory(image: image, imageName: String().generateRandomId(length: 10)))
                }
            }
            ride.save()
            hideModal()
        } else {
            if let title = titleTextField.text {
                ride.title = title
            }
            if let desc = descTextView.text {
                ride.desc = desc
            }
            ride.rideFeel = Double(feelSlider.value)
            ride.isCompleted = true
            if !images.isEmpty {
                for image in images {
                    ride.photos.insert(StorageManager.saveImageDocumentDirectory(image: image, imageName: String().generateRandomId(length: 10)))
                }
            }
            ride.save()
            ride.durationC > 3600 ? push(CongratulationsController.create(ride: ride)) : hideModal()
        }
    }
    
    //MARK: - Retrieve Images
    private func getRideImages() {
        let paths = Array(ride.photos)
        images = StorageManager.getImageFromDocumentDirectory(paths: paths)
        photoCollectionView.reloadData()
        photoCompletedCollectionView.reloadData()
    }
    
    //MARK: - IBActions
    @IBAction func feelSliderValueChanged(sender: UISlider) {
        let roundedValue: Float = sender.value < 0.33 ? 0 : (sender.value > 0.66 ? 1 : 0.5 )
        sender.value = roundedValue
    }
    @IBAction func setSliderEasyPressed(_ sender: UIButton) {
        feelSlider.value = 0
    }
    @IBAction func setSliderModeratePressed(_ sender: UIButton) {
        feelSlider.value = 0.5
    }
    @IBAction func setSliderExhaustingPressed(_ sender: UIButton) {
        feelSlider.value = 1
    }
    @IBAction func leftBarButtonPressed(_ sender: UIBarButtonItem) {
       finishRide()
    }
    @IBAction func rightBarButtonPressed(_ sender: UIBarButtonItem) {
        let nav = UINavigationController(rootViewController: CongratulationsController.create(ride: ride, isSharing: true))
        nav.modalPresentationStyle = .fullScreen
        self.showModal(nav)
    }
    @IBAction func saveDetailsButtonPressed(_ sender: UIButton) {
        finishRide()
    }
    @IBAction func upgradeButtonPressed(_ sender: UIButton) {
        showModal(FinalIntroController.create())
    }
    @IBAction func exportGPXButtonPressed(_ sender: UIButton) {
        shareGPX()
    }
}

//TextView/TextField Delegates
extension SaveAndRideDetailsController: UITextViewDelegate {
    @objc private func editingChanged(sender: UITextField) {
        let maxCharactersAllowed = 200
        guard let text = sender.text, text.count >= maxCharactersAllowed else { return }
        sender.text = String(text.dropLast(text.count - maxCharactersAllowed))
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 1000
    }
}

//MARK: - Camera
extension SaveAndRideDetailsController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageHeaderRViewDelegate, ImageCCellDelegate {
    //delegates
    func addImage() {
        CameraManager.shared.pickMedia(parentController: self, tweet: .rideDetails)
    }
    
    func deletePhoto(index: Int) {
        let isIndexValid = ride.photos.indices.contains(index)
        if isIndexValid {
            let path = Array(ride.photos)[index]
            StorageManager.deleteDirectory(path: path)
        }
        images.remove(at: index)
        photoCollectionView.reloadData()
        photoCompletedCollectionView.reloadData()
    }
}

//MARK: - CollectionView Delegates
extension SaveAndRideDetailsController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private func initCollectionView() {
        rideCollectionView.delegate = self
        rideCollectionView.dataSource = self
        rideCollectionView.register(ChartCCell.self)
        
        emptyRideCollectionView.delegate = self
        emptyRideCollectionView.dataSource = self
        emptyRideCollectionView.register(ChartCCell.self)
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.register(ImageCCell.self)
        photoCollectionView.registerFooter(ImageHeaderRView.self)
        photoCollectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        photoCompletedCollectionView.delegate = self
        photoCompletedCollectionView.dataSource = self
        photoCompletedCollectionView.register(ImageCCell.self)
        photoCompletedCollectionView.registerFooter(ImageHeaderRView.self)
        photoCompletedCollectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case rideCollectionView:                                return rideInfoAverage.count
        case emptyRideCollectionView:                           return count
        case photoCollectionView, photoCompletedCollectionView: return images.count
        default:                                                return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case rideCollectionView:
            let cell = collectionView.dequeue(ChartCCell.self, for: indexPath)
            let maxSpeed: Double = rideInfoAverage.map({$0.speed}).max() ?? 0 // get max speed
            cell.info = ChartInfo(maxSpeed: maxSpeed, speed: rideInfoAverage[indexPath.item].speed)
            cell.backView.alpha = 1.0
            return cell
        case emptyRideCollectionView:
            let cell = collectionView.dequeue(ChartCCell.self, for: indexPath)
            cell.backView.alpha = 0.5
            cell.progressBar.setProgress(0, animated: false)
            return cell
        case photoCollectionView, photoCompletedCollectionView:
            let cell = collectionView.dequeue(ImageCCell.self, for: indexPath)
            cell.imgView.image = images[indexPath.item]
            cell.delegate = self
            cell.index = indexPath.item
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch collectionView {
        case photoCollectionView, photoCompletedCollectionView:
            showModal(PreviewGalleryController.create(items: images, selectedIndex: indexPath.item))
        default:
            break
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case rideCollectionView, emptyRideCollectionView:       return CGSize(width: 2, height: collectionView.frame.height)
        case photoCollectionView, photoCompletedCollectionView: return CGSize(width: 90, height: 90)
        default:                                                return CGSize.zero
        }
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch collectionView {
        case photoCollectionView, photoCompletedCollectionView:
            guard kind == UICollectionView.elementKindSectionFooter else { return UICollectionReusableView() }
            let cell = collectionView.dequeueFooter(ImageHeaderRView.self, for: indexPath)
            cell.imgView.image = UIImage(named: images.count == 0 ? "dots1" : "dots2")
            cell.delegate = self
            return cell
        default:
            return UICollectionReusableView()
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        switch collectionView {
        case photoCollectionView, photoCompletedCollectionView:
            let width = images.count == 0 ? collectionView.frame.width - 40 : 95
            return CGSize(width: width, height: 90)
        default:
            return CGSize.zero
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        switch collectionView {
        case rideCollectionView, emptyRideCollectionView:       return 3
        case photoCollectionView, photoCompletedCollectionView: return 5
        default:                                                return CGFloat.zero
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        switch collectionView {
        case rideCollectionView, emptyRideCollectionView:       return 3
        case photoCollectionView, photoCompletedCollectionView: return 5
        default:                                                return CGFloat.zero
        }
    }
}

extension SaveAndRideDetailsController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let routePolyline = overlay as? MKPolyline else { return MKOverlayRenderer() }
        let renderer = MKPolylineRenderer(polyline: routePolyline)
        renderer.strokeColor = UIColor.TintColor
        renderer.lineWidth = 3
        return renderer
    }
}

//MARK: - ScrollableGraph
extension SaveAndRideDetailsController: ScrollableGraphViewDataSource {
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        // Return the data for each plot.
        switch(plot.identifier) {
        case "paceLine":
            return Preferences.isProUser ? Utils.mpsToSpeedOnly(ms: modifiedAverageSpeed[pointIndex]) : fakeGraph[pointIndex]
        case "altitudeLine":
            return Preferences.isProUser ? Utils.metersToFeet(meters: modifiedAverageAltitude[pointIndex]) : fakeGraph[pointIndex]
        default:
            return 0
        }
    }
    
    func label(atIndex pointIndex: Int) -> String {
        return Preferences.isProUser ? modifiedAverageDate[pointIndex].toHHmm : ""
        //return Preferences.isProUser ? Utils.secondsToHoursMinutesSeconds(seconds: rideInfo[pointIndex].time) : ""
    }
    
    func numberOfPoints() -> Int {
        return Preferences.isProUser ? modifiedAverageSpeed.count : fakeGraph.count
    }
}

extension SaveAndRideDetailsController {
    static func create(ride: Ride, images: [UIImage] = []) -> SaveAndRideDetailsController {
        let controller = UIStoryboard.main.instantiate(SaveAndRideDetailsController.self)
        controller.ride = ride
        controller.images = images
        return controller
    }
}
