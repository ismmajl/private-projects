//
//  BookingController.swift
//  luuria

import UIKit

class BookingController: ViewController {

    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var segmentController: TwicketSegmentedControl!
    @IBOutlet weak var oldTableView: UITableView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mainScrollView: UIScrollView!

    let headers = ["UPCOMING".localized,"PAST".localized]
    var newItems : [Booking] = []
    var oldItems : [Booking] = []
    var pagination: Pagination = Pagination()
    var oldPagination: Pagination = Pagination()
    lazy var pullRefresher: UIRefreshControl = {
        let r = UIRefreshControl()
        r.tintColor = Appearance.newDark
        r.addTarget(self, action: #selector(pullRefresherReload), for: .valueChanged)
        return r
    }()
    lazy var secondPullRefresher: UIRefreshControl = {
        let r = UIRefreshControl()
        r.tintColor = Appearance.newDark
        r.addTarget(self, action: #selector(secondPullRefresherReload), for: .valueChanged)
        return r
    }()
    lazy var emptyView: EmptyDataView = {
        let v = EmptyDataView.createForNoBookings()
        return v
    }()
    lazy var emptyOldView: EmptyDataView = {
        let v = EmptyDataView.createForNoBookings()
        return v
    }()
    lazy var errorView: EmptyDataView = {
        let v = EmptyDataView.createForWrong()
        return v
    }()
    var isPushed : Bool = false
    var isOld: Bool = false {
        didSet {
            if isOld != oldValue {
                UIView.animate(withDuration: 0.2, animations: {
                    if self.isOld {
                        self.segmentController.move(to: 1)
                        self.mainScrollView.setContentOffset(CGPoint.init(x: self.mainScrollView.frame.width, y: 0), animated: true)
                    }else {
                        self.segmentController.move(to: 0)
                        self.mainScrollView.setContentOffset(CGPoint.init(x: 0, y: 0), animated: true)
                    }
                })
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableInit()
        loadItems(reset: true)
        loadOldItems(reset: true)
        registerNotification(notification: .bookingChanged, selector: #selector(reloadAll))
        registerNotification(notification: .bookingCreated, selector: #selector(showConfirmedBooking))
        registerNotification(notification: .reviewCreated, selector: #selector(reloadItem))
        registerNotification(notification: .openConversationFromConfirmedPage, selector: #selector(openConversationFromConfirmed))
        headerLabel.text = "Bookings".localized.capitalized
        segmentController.setSegmentItems(headers)
        segmentController.delegate = self
        segmentController.move(to: 0)
    }
    
    func tableInit() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BookingSectionTCell.self)
        tableView.addSubview(pullRefresher)
        tableView.contentInset = UIEdgeInsets(top: 90, left: 0, bottom: 16, right: 0)
        tableView.addInfiniteScroll {[weak self] (collectionView) in
            if let indicator = collectionView.infiniteScrollIndicatorView as? UIActivityIndicatorView{
                indicator.style = .gray
            }
            self?.loadItems()
        }
        tableView.setShouldShowInfiniteScrollHandler {[weak self] (collectionView) -> Bool in
            return self?.pagination.hasNext ?? false
        }
        
        oldTableView.delegate = self
        oldTableView.dataSource = self
        oldTableView.register(BookingSectionTCell.self)
        oldTableView.addSubview(secondPullRefresher)
        oldTableView.contentInset = UIEdgeInsets(top: 90, left: 0, bottom: 16, right: 0)
        oldTableView.addInfiniteScroll {[weak self] (collectionView) in
            if let indicator = collectionView.infiniteScrollIndicatorView as? UIActivityIndicatorView{
                indicator.style = .gray
            }
            self?.loadOldItems()
        }
        oldTableView.setShouldShowInfiniteScrollHandler {[weak self] (collectionView) -> Bool in
            return self?.oldPagination.hasNext ?? false
        }
    }
    @objc func reloadAll() {
        pullRefresherReload()
        secondPullRefresherReload()
    }
    @objc func pullRefresherReload() {
        loadItems(reset: true)
    }
    @objc func secondPullRefresherReload() {
        loadOldItems(reset: true)
    }
    @objc func reloadItem(notification: NSNotification) {
        loadOldItems(reset: true)
    }
    @objc func showConfirmedBooking(notification: NSNotification) {
        guard let booking = notification.object as? Booking else { return }
        let controller = ConfirmedBookingController.create(item: booking)
        controller.modalTransitionStyle = .crossDissolve
        self.showModal(UINavigationController(rootViewController: controller))
    }
    @objc func openConversationFromConfirmed(notification: NSNotification) {
        guard let provider = notification.object as? Employee else { return }
        SalonREST.getEmployee(by: provider.id) { (provider, error) in
            if let provider = provider {
                let controller = ChatController.create(conversation: Conversation.create(provider: provider))
                self.push(controller)
            }
        }
    }
    func loadItems(reset: Bool = false) {
        let nextPage = reset ? 1 : pagination.nextPage
        if self.newItems.count == 0 {
            tableView.showLoader()
        }
        BookingREST.getBookings(page: nextPage, isActual: true) { (items, pagination, error) in
            self.tableView.hideLoader()
            self.pullRefresher.endRefreshing()
            self.tableView.finishInfiniteScroll()
            if let items = items, let pagination = pagination {
                self.errorView.hide()
                self.pagination = pagination
                if reset {
                    self.newItems.removeAll()
                }
                self.newItems += items
                if self.newItems.count == 0 {
                    self.emptyView.show(to: self.tableView)
                }else {
                    self.emptyView.hide()
                }
                dispatch {
                    self.tableView.reloadData()
                }
            }
            
            if let error = error {
                if reset {
                    self.errorView.show(to: self.tableView)
                    JSSAlertView.show(message: error.message)
                }
            }
        }
    }
    func loadOldItems(reset: Bool = false) {
        let nextPage = reset ? 1 : oldPagination.nextPage
        if oldItems.count == 0 {
            oldTableView.showLoader()
        }
        BookingREST.getBookings(page: nextPage, isActual: false) { (items, pagination, error) in
            self.oldTableView.hideLoader()
            self.secondPullRefresher.endRefreshing()
            self.oldTableView.finishInfiniteScroll()
            if let items = items, let pagination = pagination {
                self.errorView.hide()
                self.oldPagination = pagination
                if reset {
                    self.oldItems.removeAll()
                }
                self.oldItems += items
                if self.oldItems.count == 0 {
                    self.emptyOldView.show(to: self.oldTableView)
                }else {
                    self.emptyOldView.hide()
                }
                dispatch {
                    self.oldTableView.reloadData()
                }
            }
            if let error = error {
                if reset {
                    self.errorView.show(to: self.oldTableView)
                    JSSAlertView.show(message: error.message)
                }
            }
        }
    }
    @IBAction func rightBarButtonPressed(_ sender: UIBarButtonItem) {
        self.showModal(UINavigationController(rootViewController: SearchController.create(searchType: .booking)))
    }
}

//MARK: - EXTENSIONS
extension BookingController {
    static func create(isPushed: Bool = false) -> BookingController {
        let controller = UIStoryboard.bookings.instantiate(BookingController.self)
        controller.isPushed = isPushed
        return controller
    }
}

extension BookingController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tableView == oldTableView) ? oldItems.count : newItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(BookingSectionTCell.self, for: indexPath)
        cell.delegate = self
        cell.item = (tableView == oldTableView) ? oldItems[indexPath.item] : newItems[indexPath.item]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = (tableView == oldTableView) ? oldItems[indexPath.item] : newItems[indexPath.item]
        let rHeight = item.services.count * 27
        return CGFloat(rHeight + (16+23+32+20+52+32+16))
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = (tableView == oldTableView) ? oldItems[indexPath.item] : newItems[indexPath.item]
        push(BookingDetailsController.create(item: item))
    }
}

extension BookingController: BookingSectionTCellDelegate {
    func bookingSectionTCell(sender: BookingSectionTCell, item: Booking, didPressReview: UIButton) {
        self.push(CreateReviewController.create(item: item))
    }
}
extension BookingController: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        isOld = segmentIndex == 1
    }
}
