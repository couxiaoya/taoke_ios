//
//  ChartController.swift
//  TaoKe
//
//  Created by CaoYouxin on 2017/11/29.
//  Copyright © 2017年 jason tsang. All rights reserved.
//

import UIKit
import FontAwesomeKit
import MJRefresh

class ChartController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollWrapper: UIScrollView!
    @IBOutlet weak var orderImage: UIImageView!
    @IBOutlet weak var rightArrow: UIImageView!
    @IBOutlet weak var canDraw: UILabel!
    @IBOutlet weak var withDraw: UILabel!
    @IBOutlet weak var thisEstimate: UILabel!
    @IBOutlet weak var thatEstimate: UILabel!
    @IBOutlet weak var orderDetails: UIView!
    
    private var numberRegex: NSRegularExpression?
    private var maxWithDraw: Float64?
    private var canDrawState: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightArrowIcon = FAKFontAwesome.chevronRightIcon(withSize: 16)
        rightArrowIcon?.addAttribute(NSAttributedStringKey.foregroundColor.rawValue, value: UIColor("#757575"))
        rightArrow.image = rightArrowIcon?.image(with: CGSize(width: 16, height: 16))
        let orderImageIcon = FAKFontAwesome.addressBookIcon(withSize: 20)
        orderImageIcon?.addAttribute(NSAttributedStringKey.foregroundColor.rawValue, value: UIColor("#00BFFF"))
        orderImage.image = orderImageIcon?.image(with: CGSize(width: 20, height: 20))
        
        withDraw.layer.borderWidth = 1
        withDraw.layer.borderColor = UIColor("#FFD500").cgColor
        withDraw.layer.cornerRadius = 15
        
        initScroll()
        initCanDraw()
        initThisEstimate()
        initThatEstimate()
        
        numberRegex = try? NSRegularExpression(pattern: "^(\\d{1,})?(\\.\\d{0,2})?$")
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        withDraw.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        orderDetails.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if let matches = numberRegex?.matches(in: newText, options: [], range: NSMakeRange(0, (newText as NSString).length)) {
            return matches.count > 0
        } else {
            return false
        }
    }
    
    @objc private func tap(_ sender: UITapGestureRecognizer) {
        switch sender.view! {
        case withDraw:
            if !canDrawState {
                return;
            }
            
            if maxWithDraw! < 10.0 {
                let amountTooLow = UIAlertController(title: "", message: "至少10元才可提现", preferredStyle: .alert)
                amountTooLow.addAction(UIAlertAction(title: "了解", style: .cancel, handler: { (action) in
                }))
                self.present(amountTooLow, animated: true)
            }
            
            canDrawState = false
            
            let alert = UIAlertController(title: "", message: "请输入提现金额", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.keyboardType = .numbersAndPunctuation
                textField.delegate = self
            })
            alert.addAction(UIAlertAction(title: "提交", style: .default, handler: { (action) in
                if let input = alert.textFields?[0].text {
                    if let inputAmount = Float64(input) {
                        if inputAmount >= self.maxWithDraw! {
                            let _ = TaoKeApi.withDraw(input).rxSchedulerHelper().handlerError({
                                self.canDrawState = true
                                let msg = UIAlertController(title: "", message: "购买者不享有此功能", preferredStyle: .actionSheet)
                                msg.addAction(UIAlertAction(title: "了解", style: .cancel, handler: { (action) in
                                }))
                                self.present(msg, animated: true)
                            }).subscribe(onNext: { _ in
                                self.initCanDraw()
                                let msg = UIAlertController(title: "", message: "已经为您创建提现申请记录，工作人员会及时与您取得联系", preferredStyle: .actionSheet)
                                msg.addAction(UIAlertAction(title: "了解", style: .cancel, handler: { (action) in
                                }))
                                self.present(msg, animated: true)
                            })
                        }
                    } else {
                        self.canDrawState = true
                    }
                }
            }))
            self.present(alert, animated: true)
            break;
        case orderDetails:
            let alert = UIAlertController(title: "", message: "待开发", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: { (action) in
            }))
            self.present(alert, animated: true)
            break;
        default:
            break;
        }
    }
    
    private func initScroll() {
        scrollWrapper.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            
            self.initCanDraw()
            self.initThisEstimate()
            self.initThatEstimate()
            
            let delayTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.scrollWrapper.mj_header.endRefreshing()
            }
        })
    }
    
    private func initThatEstimate() {
        let _ = TaoKeApi.getThisEstimate().rxSchedulerHelper().handleUnAuth(viewController: self)
            .subscribe(onNext: { (data) in
                let text = "本月结算效果预估\n¥ \(data)"
                let attribuites = NSMutableAttributedString(string: text)
                let location = (text.index(of: "¥")?.encodedOffset)! + 2
                let length = (text.index(of: ".")?.encodedOffset)! - location
                let range = NSRange(location: location, length: length)
                attribuites.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 28), range: range)
                self.thisEstimate.attributedText = attribuites
                self.thisEstimate.numberOfLines = 0
            })
    }
    
    private func initThisEstimate() {
        let _ = TaoKeApi.getThatEstimate().rxSchedulerHelper().handleUnAuth(viewController: self)
            .subscribe(onNext: { (data) in
                let text = "上月结算效果预估\n¥ \(data)"
                let attribuites = NSMutableAttributedString(string: text)
                let location = (text.index(of: "¥")?.encodedOffset)! + 2
                let length = (text.index(of: ".")?.encodedOffset)! - location
                let range = NSRange(location: location, length: length)
                attribuites.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 28), range: range)
                self.thatEstimate.attributedText = attribuites
                self.thatEstimate.numberOfLines = 0
            })
    }
    
    private func initCanDraw() {
        let _ = TaoKeApi.getCanDraw().rxSchedulerHelper().handleUnAuth(viewController: self)
            .subscribe(onNext: { (data) in
                let text = "¥ \(data)"
                let attribuites = NSMutableAttributedString(string: text)
                let location = (text.index(of: "¥")?.encodedOffset)! + 2
                let length = (text.index(of: ".")?.encodedOffset)! - location
                let range = NSRange(location: location, length: length)
                attribuites.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 28), range: range)
                self.canDraw.attributedText = attribuites
                self.maxWithDraw = Float64(data)
                self.canDrawState = true
            })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
