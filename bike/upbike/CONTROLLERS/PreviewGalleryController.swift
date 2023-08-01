//
//  PreviewGalleryController.swift
//  combike

import UIKit

class PreviewGalleryController: ViewController {
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var fakeImgView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    private var selectedIndex: Int = 0
    private var items: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionInit()
        setValues()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setValues() {
        countLabel.text = "\(selectedIndex + 1)/\(items.count)"
        collectionView.reloadData()
        delay(delay: 0.01) {
            self.collectionView.scrollToItem(at: IndexPath(item: self.selectedIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    private func collectionInit() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PreviewImageCCell.self)
        collectionView.contentInsetAdjustmentBehavior = .never
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        collectionView.collectionViewLayout = flowLayout
    }
    
    private func changePage() {
        let index = Int(collectionView.contentOffset.x / collectionView.frame.size.width)
        guard items.count > 0 else { return }
        countLabel.text = "\(index + 1)/\(items.count)"
        selectedIndex = index
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        //
    }
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        self.hideModal()
    }
}

extension PreviewGalleryController {
    static func create(items: [UIImage], selectedIndex: Int) -> PreviewGalleryController {
        let controller = UIStoryboard.misc.instantiate(PreviewGalleryController.self)
        controller.items = items
        controller.selectedIndex = selectedIndex
        return controller
    }
}

extension PreviewGalleryController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(PreviewImageCCell.self, for: indexPath)
        cell.item = items[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        changePage()
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //
    }
}
