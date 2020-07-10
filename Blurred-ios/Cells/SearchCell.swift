//
//  SearchCell.swift
//
//
//  Created by Martin Velev on 6/30/20.
//

// Warning
// Cell currently not in use
import UIKit

class SearchCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    @IBOutlet weak var searchFollowerCount: UILabel!
    @IBOutlet weak var searchBio: UILabel!
    @IBOutlet weak var searchUsername: UILabel!
    @IBOutlet weak var searchName: UILabel!
    @IBOutlet weak var searchAvatar: UIImageView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    override func prepareForReuse() {
           super.prepareForReuse()
        searchAvatar.image = nil
           isHidden = false
           isSelected = false
           isHighlighted = false
       }

}
