//
//  BrowserVC.swift
//  TheMaxPlace
//
//  Created by developer91 on 5/9/17.
//  Copyright © 2017 Lanetteam. All rights reserved.
//

import UIKit

class BrowserVC: UIViewController,UIWebViewDelegate {
    
    @IBOutlet var webVW: UIWebView!
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserVC.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        Reach().monitorReachabilityChanges()
        self.webVW.delegate = self
        self.loadRequestInWebview()
        self.navigationController?.navigationBar.isHidden = true
        webVW.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        addPullToRefreshToWebView()
        if ((UserDefaults.standard.object(forKey: "IsDeviceRegistered") as? String) == nil){
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector:  #selector(BrowserVC.checkIfSessionExist), userInfo: nil, repeats: true)
        }

    }
    func loadRequestInWebview()  {
        if let url = NSURL(string: "http://themaxplace.com") {
            let request = URLRequest(url: url as URL) as URLRequest
            webVW.loadRequest(request)
        }
    }
    func networkStatusChanged(_ notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo! as! [String: String]
        let val = userInfo["Status"]!
        if val == "offline" || val == "unknown" {
            self.showALertMessages()
        }
        else{
            webVW.stopLoading()
            if webVW.request?.url?.absoluteString == "" || webVW.request?.url == nil {
                self.loadRequestInWebview()
            }else{
                webVW.reload()
            }
        }
    }
    func addPullToRefreshToWebView() {
        let whiteColor = UIColor.white
        let refreshController = UIRefreshControl()
        refreshController.bounds = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(refreshController.bounds.size.width), height: CGFloat(refreshController.bounds.size.height))
        refreshController.addTarget(self, action: #selector(self.refreshWebView), for: .valueChanged)
        refreshController.tintColor = whiteColor
        webVW.scrollView.addSubview(refreshController)
    }
    func refreshWebView(_ refreshController: UIRefreshControl) {
        webVW.reload()
        refreshController.endRefreshing()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews();
        webVW.scrollView.contentInset = .zero
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        if timer.isValid {
        }
        else{
            self.checkIfSessionExist()
        }
    }
    func showALertMessages()  {
        let alert = UIAlertController(title: "TheMaxPlace", message: "The Internet connection appears to be offline.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func checkIfSessionExist()
    {
        
        if Reach().connectionStatus().description == "Unknown" || Reach().connectionStatus().description == "Offline"{
            self.showALertMessages()
            return
        }
        let requestURL: NSURL = NSURL(string: "http://themaxplace.com/api/g_id.php")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {(data, response, error) -> Void in
            if response != nil {
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                if (statusCode == 200) {
                    let userId = String(data: data!, encoding: .utf8)
                    if Int(userId!)! > 0
                    {
                        if ((UserDefaults.standard.object(forKey: "IsDeviceRegistered") as? String) != nil) && ((UserDefaults.standard.object(forKey: "DateOfDeviceRegistration") as? Date) != nil)
                        {
                            let dateOFDevice = UserDefaults.standard.object(forKey:"DateOfDeviceRegistration") as? Date
                            let isDeviceRegistered = UserDefaults.standard.object(forKey:"IsDeviceRegistered") as? String
                            let datestring = dateOFDevice?.ToLocalStringWithFormat(dateFormat: "yyyy-MM-dd")
                            let currentDateString = Date().ToLocalStringWithFormat(dateFormat: "yyyy-MM-dd")
                            if datestring == currentDateString && isDeviceRegistered == "YES"
                            {
                                
                            }
                            else{
                                self.registerDeviceForPush(userid: userId!)
                            }
                        }
                        else{
                            self.registerDeviceForPush(userid: userId!)
                        }
                    }
                    print(userId!)
                } else  {
                    
                }
            }
        }
        task.resume()
    }
    
    func registerDeviceForPush(userid: String)
    {
        if (UserDefaults.standard.object(forKey: "DeviceToken") as? String) != nil
        {
            let deviceToken = UserDefaults.standard.object(forKey:"DeviceToken") as? String
            
            let requestURL: NSURL = NSURL(string: "http://themaxplace.com/api/Get_Device.php?user_id=" + userid + "&device=" + deviceToken!)!
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest as URLRequest) {(data, response, error) -> Void in
                if response != nil {
                    let httpResponse = response as! HTTPURLResponse
                    let statusCode = httpResponse.statusCode
                    if (statusCode == 200)
                    {
                        let userId = String(data: data!, encoding: .utf8)
                        if userId?.lowercased().range(of:"success") != nil
                        {
                            self.timer.invalidate()
                            UserDefaults.standard.set("YES", forKey: "IsDeviceRegistered")
                            UserDefaults.standard.set(Date(), forKey:"DateOfDeviceRegistration")
                            UserDefaults.standard.synchronize()
                        }
                    }
                    else
                    {
                        
                    }
                }
            }
            task.resume()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

