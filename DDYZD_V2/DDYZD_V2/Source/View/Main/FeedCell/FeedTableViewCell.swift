//
//  FeedTableViewCell.swift
//  DDYZD_V2
//
//  Created by 김수완 on 2021/02/07.
//

import UIKit

import RxSwift

class FeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellSuperView: UIView!
    @IBOutlet weak var clubProfileImageView: UIImageView!
    @IBOutlet weak var clubName: UILabel!
    @IBOutlet weak var uploadAt: UILabel!
    @IBOutlet weak var goClubDetailArea: UIButton!
    @IBOutlet weak var content: UITextView!
    @IBOutlet weak var flagNum: UILabel!
    @IBOutlet weak var MenuBtn: UIButton!
    @IBOutlet weak var flagBtn: UIButton!
    
    public var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setUI()
        setTextView()
    }
    
    func setTextView(){
        content.isEditable = false
        content.dataDetectorTypes = .link
    }
    
    func setUI() {
        clubProfileImageView.circleImage()
        cellSuperView.layer.borderColor = #colorLiteral(red: 0.2078431373, green: 0.03484285995, blue: 0.4432567954, alpha: 1)
    }

    func bind(item: Feed) {
        if item.pin ?? false {
            cellSuperView.layer.borderWidth = 1
        }
        clubProfileImageView.kf.setImage(with: kfImageURL(url: item.profileImage, type: .half))
        clubName.text = item.clubName
        uploadAt.dateLabel(item.uploadAt)
        content.text = item.content
        flagBtn.isSelected = item.flag
        flagNum.text = String(item.flags)
    }
}
