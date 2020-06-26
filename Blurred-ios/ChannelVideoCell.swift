//
//  ChannelVideoCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 5/29/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class ChannelVideoCell: UICollectionViewCell {
    @IBOutlet weak var thumbnailView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = UIImage(named: "load-image")
        isHidden = false
        isSelected = false
        isHighlighted = false
    }
}
