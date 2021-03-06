//
//  AnswerChatHelperTableViewCell.swift
//  DDYZD_V2
//
//  Created by 김수완 on 2021/03/03.
//

import UIKit

class AnswerChatHelperTableViewCell: UITableViewCell {
    
    @IBOutlet weak var helperCellView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var whenLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setUI()
    }
    
    func setUI(){
        self.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        helperCellView.layer.borderWidth = 1
        helperCellView.layer.borderColor = #colorLiteral(red: 0.874435842, green: 0.8745588064, blue: 0.8743970394, alpha: 1)
        helperCellView.layer.cornerRadius = 10
    }
}
