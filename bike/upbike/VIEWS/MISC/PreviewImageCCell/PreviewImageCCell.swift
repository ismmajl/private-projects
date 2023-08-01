//
//  PreviewImageCCell.swift
//  combike

import UIKit

class PreviewImageCCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var item: UIImage! {
        didSet {
            imageView.image = item
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
