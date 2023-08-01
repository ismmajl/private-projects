//
//  HistoryController.swift
//  upbike
//
//  Created by Agon Miftari on 12/24/19.
//  Copyright © 2019 Tenton. All rights reserved.
//

import UIKit
import FSCalendar

class HistoryController: ViewController {
    
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectTimeBarButton: UIBarButtonItem!
    @IBOutlet weak var deleteHistoryBarButton: UIBarButtonItem!
    
    var items: [Ride] = []
    var histories: [String] = ["--- TOTAL OVERVIEW ---", "--- MONTHLY OVERVIEW ---", "--- WEEKLY OVERVIEW ---"]
    var timeFilter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        tableInit()
        NotificationCenter.default.addObserver(self, selector: #selector(loadItems), name: .ridesChanged, object: nil)
//        modeChanged()
//        NotificationCenter.default.addObserver(self, selector: #selector(modeChanged), name: .modeChanged, object: nil)
    }
    
//    @objc func modeChanged() {
//        if #available(iOS 13.0, *) {
//            overrideUserInterfaceStyle = Preferences.isAppLightMode ? .light : .dark
//            UIApplication.shared.statusBarStyle = Preferences.isAppLightMode ? .default: .lightContent        }
//    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadItems()
    }
    
    func setup() {
        deleteHistoryBarButton.tintColor = .clear
        deleteHistoryBarButton.isEnabled = false
        
        calendar.scope = .week
        calendar.delegate = self
        calendar.dataSource = self
    }
    
    @objc func loadItems() {
        let rides: [Ride] = Ride.all().toArray()
        self.items = Array(rides.sorted(by: { $0.getStartDate() > $1.getStartDate() }))
        self.tableView.reloadData()
        emptyLabel.isHidden = !(self.items.count == 0)
        tableView.tableHeaderView?.frame.size.height = !(self.items.count == 0) ? 200 : 0
        self.tableView.isScrollEnabled = !(self.items.count == 0)
        tableView.tableHeaderView?.alpha = !(self.items.count == 0) ? 1.0 : 0.0
    }
    
    func tableInit() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HistoryStatsTCell.self)
        tableView.register(HistoryTCell.self)
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
    }
    
    func openActionSheet() {
        let items = ["All time", "Monthly", "Weekly", "Daily"]
        let controller = ActionSheetController.create(items: items)
        controller.didPressItem = { itemCase in
            switch itemCase {
            case "All time":
                self.timeFilter = 0
            case "Monthly":
                self.timeFilter = 1
            case "Weekly", "Daily":
                self.timeFilter = 2
            default:
                break
            }
            self.tableView.reloadData()
        }
        self.showModal(controller)
    }
    
    //MARK: - IBActions
    @IBAction func rightBarButtonPressed(_ sender: UIBarButtonItem) {
        guard self.items.count > 0 else { return }
        let alert = UIAlertController(title: "Are you sure you want to clear history?", message: "", preferredStyle: .alert)
        if #available(iOS 13.0, *) {
            alert.setTitlet(font: Appearance.mediumFont(size: 20), color: UIColor.label)
            alert.setBackgroundColor(color: UIColor.systemBackground)
        } else {
            alert.setTitlet(font: Appearance.mediumFont(size: 20), color: UIColor.white)
            alert.setBackgroundColor(color: Appearance.darkColor)
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
            self.items.delete()
            self.loadItems()
        }))
        alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
        alert.setTint(color: UIColor.TintColor)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func selectTimeBarButton(_ sender: UIBarButtonItem) {
        openActionSheet()
    }
    
}

//MARK: - TableView Delegate
extension HistoryController: UITableViewDelegate, UITableViewDataSource, HistoryTCellDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        case 0:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = .clear
            return cell
            
        case 1:
            let cell = tableView.dequeue(HistoryStatsTCell.self, for: indexPath)
            
            let isEnglish = Locale.current.languageCode == "en"
            let zero = isEnglish ? "0,0" : "0.0"
            let isMile = Preferences.distanceUnit == "mi"
            let speedFormat = isMile ? "mph" : "km/h"
            let altitudeFormat = isMile ? "ft" : "m"
            var distances: Double = 0.0
            
            cell.timeLabel.text = "00:00"
            cell.caloriesLabel.text = "00"
            cell.distanceLabel.set(title: zero, with: 24, subTitle: Preferences.distanceUnit, with: 14)
            cell.maxSpeedLabel.set(title: zero, with: 24, subTitle: speedFormat, with: 14)
            cell.maxAltitudeLabel.set(title: "00", with: 24, subTitle: altitudeFormat, with: 14)
            cell.minAltitudeLabel.set(title: "00", with: 24, subTitle: altitudeFormat, with: 14)
            
            switch timeFilter {
            case 0:
                // total
                for d in items {
                    let distance = Measurement.init(value: d.getDistance(), unit: UnitLength.meters).converted(to: UnitLength.miles)
                    distances = distances + distance.value
                }
                var distanceString = String(distances.rounded(places: 2))
                distanceString = distanceString.replacingOccurrences(of: isEnglish ? "." : ",", with: isEnglish ? "," : ".")
                
                cell.distanceLabel.set(title: String(distanceString), with: 24, subTitle: Preferences.distanceUnit.lowercased(), with: 14)
                
                let duration = items.map({$0.getDuration()}).reduce(0, +)
                cell.timeLabel.text = Double(duration).asString(style: .positional)
                
                cell.caloriesLabel.text = String(items.map({$0.getCalories()}).reduce(0, +))
                
                let speed = items.map({$0.getMaxSpeed()})
                cell.maxSpeedLabel.set(title: Utils.maxSpeed(from: speed), with: 24, subTitle: speedFormat, with: 14)
                
                let minAltitude = items.map({$0.getMinAltitude()}).min() ?? 0
                let maxAltitude = items.map({$0.getMaxAltitude()}).max() ?? 0
                cell.minAltitudeLabel.set(title: Utils.calculateAltitude(altitude: minAltitude), with: 24, subTitle: altitudeFormat, with: 14)
                cell.maxAltitudeLabel.set(title: Utils.calculateAltitude(altitude: maxAltitude), with: 24, subTitle: altitudeFormat, with: 14)

                break
            case 1:
                //this month
                let thisMonth = items.filter {
                    return Calendar.current.component(.month, from: $0.getStartDate()) == Calendar.current.component(.month, from: Date())
                }
                
                for d in thisMonth {
                    let distance = Measurement.init(value: d.getDistance(), unit: UnitLength.meters).converted(to: UnitLength.miles)
                    distances = distances + distance.value
                }
                var distanceString = String(distances.rounded(places: 2))
                distanceString = distanceString.replacingOccurrences(of: isEnglish ? "." : ",", with: isEnglish ? "," : ".")
                cell.distanceLabel.set(title: String(distanceString), with: 24, subTitle: Preferences.distanceUnit.lowercased(), with: 14)

                let duration = thisMonth.map({$0.getDuration()}).reduce(0, +)
                cell.timeLabel.text = Double(duration).asString(style: .positional)
                
                cell.caloriesLabel.text = String(thisMonth.map({$0.getCalories()}).reduce(0, +))
                
                let speed = thisMonth.map({$0.getMaxSpeed()})
                cell.maxSpeedLabel.set(title: Utils.maxSpeed(from: speed), with: 24, subTitle: speedFormat, with: 14)
                
                let minAltitude = thisMonth.map({$0.getMinAltitude()}).min() ?? 0
                let maxAltitude = thisMonth.map({$0.getMaxAltitude()}).max() ?? 0
                cell.minAltitudeLabel.set(title: Utils.calculateAltitude(altitude: minAltitude), with: 24, subTitle: altitudeFormat, with: 14)
                cell.maxAltitudeLabel.set(title: Utils.calculateAltitude(altitude: maxAltitude), with: 24, subTitle: altitudeFormat, with: 14)

                break
            case 2:
                //this week
                let thisWeek = items.filter {
                    return Calendar.current.component(.weekOfYear, from: $0.getStartDate()) == Calendar.current.component(.weekOfYear, from: Date())
                }
                
                for d in thisWeek {
                    let distance = Measurement.init(value: d.getDistance(), unit: UnitLength.meters).converted(to: UnitLength.miles)
                    distances = distances + distance.value
                }
                var distanceString = String(distances.rounded(places: 2))
                distanceString = distanceString.replacingOccurrences(of: isEnglish ? "." : ",", with: isEnglish ? "," : ".")
                cell.distanceLabel.set(title: String(distanceString), with: 24, subTitle: Preferences.distanceUnit.lowercased(), with: 14)

                let duration = thisWeek.map({$0.getDuration()}).reduce(0, +)
                cell.timeLabel.text = Double(duration).asString(style: .positional)
                
                cell.caloriesLabel.text = String(thisWeek.map({$0.getCalories()}).reduce(0, +))
                
                let speed = thisWeek.map({$0.getMaxSpeed()})
                cell.maxSpeedLabel.set(title: Utils.maxSpeed(from: speed), with: 24, subTitle: speedFormat, with: 14)
                
                let minAltitude = thisWeek.map({$0.getMinAltitude()}).min() ?? 0
                let maxAltitude = thisWeek.map({$0.getMaxAltitude()}).max() ?? 0
                cell.minAltitudeLabel.set(title: Utils.calculateAltitude(altitude: minAltitude), with: 24, subTitle: altitudeFormat, with: 14)
                cell.maxAltitudeLabel.set(title: Utils.calculateAltitude(altitude: maxAltitude), with: 24, subTitle: altitudeFormat, with: 14)

            default:
                break
            }
            return cell
            
        case 2:
            let cell = tableView.dequeue(HistoryTCell.self, for: indexPath)
            cell.items = items.filter {$0.mode == .free}
            cell.delegate = self
            return cell
            
        case 3:
            let cell = tableView.dequeue(HistoryTCell.self, for: indexPath)
            cell.items = items.filter {$0.mode == .time}
            cell.delegate = self
            return cell
            
        case 4:
            let cell = tableView.dequeue(HistoryTCell.self, for: indexPath)
            cell.items = items.filter {$0.mode == .distance}
            cell.delegate = self
            return cell
            
        case 5:
            let cell = tableView.dequeue(HistoryTCell.self, for: indexPath)
            cell.items = items.filter {$0.mode == .calories}
            cell.delegate = self
            return cell
        
        default:
            return UITableViewCell()
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 40
        case 1:
            return items.count > 0 ? UITableView.automaticDimension : 0.01
        case 2:
            return items.filter {$0.mode == .free}.count > 0 ? UITableView.automaticDimension : 0.01
        case 3:
            return items.filter {$0.mode == .time}.count > 0 ? UITableView.automaticDimension : 0.01
        case 4:
            return items.filter {$0.mode == .distance}.count > 0 ? UITableView.automaticDimension : 0.01
        case 5:
            return items.filter {$0.mode == .calories}.count > 0 ? UITableView.automaticDimension : 0.01
        default:
            return 0
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
//            timeFilter = timeFilter != 3 ? timeFilter + 1 : 0
//            tableView.reloadSections(IndexSet([0]), with: .automatic)
            break
        default:
            break
        }
        //tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //return true
        return false
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.items[indexPath.row].delete()
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.emptyLabel.isHidden = !(self.items.count == 0)
            self.tableView.tableHeaderView?.frame.size.height = !(self.items.count == 0) ? 200 : 0
            self.tableView.tableHeaderView?.alpha = !(self.items.count == 0) ? 1.0 : 0.0
        }
    }
    
    func pushRide(item: Ride) {
        let nav = UINavigationController(rootViewController: SaveAndRideDetailsController.create(ride: item))
        nav.modalPresentationStyle = .fullScreen
        self.showModal(nav)
    }
}

//MARK: - Calendar
extension HistoryController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = CGRectGetHeight(bounds) + 10
        self.view.layoutIfNeeded()
    }
}

extension HistoryController {
    static func create() -> HistoryController {
        let controller = UIStoryboard.history.instantiate(HistoryController.self)
        return controller
    }
}
