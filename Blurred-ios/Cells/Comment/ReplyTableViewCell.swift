//
//  ReplyTableViewCell.swift
//  Blurred-ios
//
//  Created by Martin Velev on 10/25/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import UIKit

class ReplyTableViewCell: UITableViewCell {
    
    // MARK: Variables and Properties
    
    var commentId = Int()
    var indexPath = IndexPath()
    var parentId = Int()
    var delegate: CommentCellDelegate?
    @IBOutlet weak var likeNumber: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    @IBOutlet weak var comment: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.likeButtonTap(sender:)))
        likeButton.addGestureRecognizer(tap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: Like Button Tapped
    @objc func likeButtonTap(sender:UITapGestureRecognizer) {
        delegate?.likeButtonTapped(commentId: commentId, indexPath: indexPath, reply: true)
    }

}
