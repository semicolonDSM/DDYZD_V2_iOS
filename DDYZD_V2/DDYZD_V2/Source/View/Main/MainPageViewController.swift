//
//  MainPageViewController.swift
//  DDYZD_V2
//
//  Created by 김수완 on 2021/01/24.
//

import UIKit

import RxCocoa
import RxSwift
import WebKit
import SwiftOverlays

class MainPageViewController: UIViewController {
    
    @IBOutlet weak var headerWKView: WKWebView!
    @IBOutlet weak var feedTable: UITableView!
    
    private let viewModel = MainPageViewModel()
    private let disposeBag = DisposeBag()
    private var loadMore = false
    
    private let tokenRefresh = PublishSubject<Void>()
    private let getFeed = PublishSubject<LoadFeedAction>()
    private let flagIt = PublishSubject<Int>()
    private let deleteFeed = PublishSubject<Int>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showWaitOverlay()
        presentTOS()
        bind()
        refreshToken()
        setHeaderWKView()
        setTableView()
        registerCell()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setNavigationbar()
    }
    
    func bind() {
        let input = MainPageViewModel.input.init(tokenRefresh: tokenRefresh.asDriver(onErrorJustReturn: ()),
                                                 getFeed: getFeed.asDriver(onErrorJustReturn: .reload),
                                                 flagIt: flagIt.asDriver(onErrorJustReturn: 0),
                                                 deleteFeed: deleteFeed.asDriver(onErrorJustReturn: -1))
        let output = viewModel.transform(input)
        
        output.tokenRefreshResult.subscribe{ _ in
            self.reloadFeeds()
        }
        .disposed(by: disposeBag)
        
        output.feedList.bind(to: feedTable.rx.items) { tableView, row, item -> UITableViewCell in
            self.removeAllOverlays()
            self.loadMore = false
            if item.media.isEmpty { 
                let cell = self.feedTable.dequeueReusableCell(withIdentifier: "Feed") as! FeedTableViewCell
                
                cell.bind(item: item)
                
                cell.content.delegate = self
                
                cell.goClubDetailArea.rx.tap.subscribe(onNext: {
                    self.goClubDetailView(item.clubId!)
                })
                .disposed(by: cell.disposeBag)
                
                cell.MenuBtn.rx.tap.subscribe(onNext: {
                    self.menuActionSheet(item: item, isHead: nil, pinCloser: nil){
                        self.deleteFeed.onNext(row)
                    }
                })
                .disposed(by: cell.disposeBag)
                
                cell.flagBtn.rx.tap.subscribe(onNext: {
                    self.flagIt.onNext(row)
                }).disposed(by: cell.disposeBag)
                
                return cell
            } else {
                let cell = self.feedTable.dequeueReusableCell(withIdentifier: "FeedWithMedia") as! FeedWithMediaTableViewCell
                
                cell.bind(item: item)
                
                cell.content.delegate = self
                
                cell.goClubDetailArea.rx.tap.subscribe(onNext: {
                    self.goClubDetailView(item.clubId!)
                })
                .disposed(by: cell.disposeBag)
                
                cell.MenuBtn.rx.tap.subscribe(onNext: {
                    self.menuActionSheet(item: item, isHead: nil, pinCloser: nil){
                        self.deleteFeed.onNext(row)
                    }
                })
                .disposed(by: cell.disposeBag)
                
                cell.flagBtn.rx.tap.subscribe(onNext: {
                    self.flagIt.onNext(row)
                }).disposed(by: cell.disposeBag)
                
                return cell
            }
        }
        .disposed(by: disposeBag)
        
        output.flagItResult.subscribe(onNext: { isSuccess in
            if !isSuccess{
                self.moveLogin(didJustBrowsingBtnTaped: nil, didSuccessLogin: nil)
            }
        })
        .disposed(by: disposeBag)
    }
    
    func refreshToken(){
        tokenRefresh.onNext(())
    }
    
    func reloadFeeds(){
        getFeed.onNext(.reload)
    }
    
    func loadMoreFeeds(){
        loadMore = true
        getFeed.onNext(.loadMore)
    }
    
}

// MARK:- UI
extension MainPageViewController {
    func setNavigationbar(){
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let customView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 44.0))

        let icon = UIImageView(image: UIImage(named: "icon"))
        icon.contentMode = .scaleToFill
        icon.frame = CGRect(x: 0.0, y: 5.0, width: 30.0, height: 30.0)
        customView.addSubview(icon)

        let marginX = CGFloat(icon.frame.origin.x + icon.frame.size.width - 30)
        let label = UILabel(frame: CGRect(x: marginX, y: 0.0, width: 150.0, height: 44.0))
        label.text = "대동여지도"
        label.font = UIFont.systemFont(ofSize: 25)
        label.textAlignment = NSTextAlignment.right
        customView.addSubview(label)

        let leftButton = UIBarButtonItem(customView: customView)
        navigationItem.leftBarButtonItem = leftButton
    }
    
    func presentTOS(){
        if UserDefaults.standard.bool(forKey: "isAgreeTOS") != true {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let tosViewController = mainStoryboard.instantiateViewController(withIdentifier: "TOSViewController") as! TOSViewController
            UIApplication.topViewController()?.present(tosViewController, animated: true, completion: nil)
        }
    }
}

// MARK:- table view
extension MainPageViewController: UITableViewDelegate {
    
    func setHeaderWKView() {
        let URL = "https://ddyzd.dsmkr.com/mobile/banner"
        let request: URLRequest = URLRequest.init(url: NSURL.init(string: URL)! as URL, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10)
        headerWKView.load(request)
        headerWKView.scrollView.isScrollEnabled = false
        feedTable.tableHeaderView?.frame.size.height = headerWKView.frame.height
    }
    
    func setTableView(){
        feedTable.separatorStyle = .none
        feedTable.allowsSelection = false
        feedTable.delegate = self
        initRefresh()
    }
    
    func registerCell() {
        let feedNib = UINib(nibName: "Feed", bundle: nil)
        feedTable.register(feedNib, forCellReuseIdentifier: "Feed")
        let feedWithMediadNib = UINib(nibName: "FeedWithMedia", bundle: nil)
        feedTable.register(feedWithMediadNib, forCellReuseIdentifier: "FeedWithMedia")
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FeedTableViewCell {
            cell.disposeBag = DisposeBag()
            cell.flagBtn.isSelected = false
        } else if let cell = cell as? FeedWithMediaTableViewCell {
            cell.disposeBag = DisposeBag()
            cell.flagBtn.isSelected = false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
                
        if offsetY > contentHeight - scrollView.frame.height{
            if !loadMore {
                loadMoreFeeds()
            }
        }
    }
    
    func initRefresh() {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshFeed(refresh:)), for: .valueChanged)
        feedTable.refreshControl = refresh
    }
    
    @objc func refreshFeed(refresh: UIRefreshControl) {
        refresh.endRefreshing()
        reloadFeeds()
        setHeaderWKView()
    }
}

// MARK:- TextView
extension MainPageViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.openInSafari(url: URL)
        return false
    }
    
}
