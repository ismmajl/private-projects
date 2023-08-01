//
//  ProgramController.swift
//  Radio1
//
//  Created by ismmajl on 12/08/2019.
//  Copyright © 2019 Radio1. All rights reserved.
//

import UIKit
import SwiftDate
import ViewAnimator

class ProgramController: UIViewController {

    //MARK: - OUTLETS
    @IBOutlet weak var sundayButton: UIButton!
    @IBOutlet weak var saturdayButton: UIButton!
    @IBOutlet weak var fridayButton: UIButton!
    @IBOutlet weak var thursdayButton: UIButton!
    @IBOutlet weak var wednesdayButton: UIButton!
    @IBOutlet weak var tuesdayButton: UIButton!
    @IBOutlet weak var mondayButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - VARIABLES
    var shows: [Show] = []
    private let animations = [AnimationType.from(direction: .bottom, offset: 50.0)]

    //MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews(dayofWeek: Date().getDayOfWeek())
        tableInit()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationChangedState), name: NSNotification.Name(rawValue: "ApplicationStatusChanged"), object: nil)
    }
    
    func tableInit() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ShowTCell.self)
    }
    
    @objc func applicationChangedState(notitication: Notification) {
        self.tableView.reloadData()
    }
    
    func setupViews(dayofWeek: DayOfWeek) {
        getProgram(by: dayofWeek)
        mondayButton.setTitleColor(setDayColor(bool: dayofWeek == .monday), for: .normal)
        mondayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .monday)
        tuesdayButton.setTitleColor(setDayColor(bool: dayofWeek == .tuesday), for: .normal)
        tuesdayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .tuesday)
        wednesdayButton.setTitleColor(setDayColor(bool: dayofWeek == .wednesday), for: .normal)
        wednesdayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .wednesday)
        thursdayButton.setTitleColor(setDayColor(bool: dayofWeek == .thursday), for: .normal)
        thursdayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .thursday)
        fridayButton.setTitleColor(setDayColor(bool: dayofWeek == .friday), for: .normal)
        fridayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .friday)
        saturdayButton.setTitleColor(setDayColor(bool: dayofWeek == .saturday), for: .normal)
        saturdayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .saturday)
        sundayButton.setTitleColor(setDayColor(bool: dayofWeek == .sunday), for: .normal)
        sundayButton.titleLabel?.font = setDayFont(bool: dayofWeek == .sunday)
    }
    func setDayColor(bool: Bool) -> UIColor {
        return bool ? UIColor.white : UIColor.white.withAlphaComponent(0.44)
    }
    func setDayFont(bool: Bool) -> UIFont {
        return (bool ? UIFont(name: "AvenirNext-DemiBold", size: 14.0) : UIFont(name: "AvenirNext-Regular", size: 14.0))!
    }
    func getProgram(by dayofWeek: DayOfWeek) {
        DispatchQueue.main.async {
            UIView.animate(views: self.tableView.visibleCells, animations: self.animations)
            self.shows = Program.getShows(by: dayofWeek)
            self.tableView.reloadData()
        }
    }
    
    //MARK: - ACTIONS
    @IBAction func sundayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .sunday)
    }
    @IBAction func saturdayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .saturday)
    }
    @IBAction func fridayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .friday)
    }
    @IBAction func thursadayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .thursday)
    }
    @IBAction func wednesdayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .wednesday)
    }
    @IBAction func tuesdayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .tuesday)
    }
    @IBAction func mondayButtonPressed(_ sender: UIButton) {
        setupViews(dayofWeek: .monday)
    }
}
//MARK: - TABLEVIEW EXTENSIONS
extension ProgramController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shows.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ShowTCell.self, for: indexPath)
        cell.show = shows[indexPath.item]
        cell.sImage.image = UIImage(named: Program.isPlaying(show: shows[indexPath.item]) ? "selected" : "unselected")
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return min(44, UITableView.automaticDimension)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let show = shows[indexPath.item]
        self.present(ShowDescriptionController.create(show: show), animated: true, completion: nil)
    }
}
