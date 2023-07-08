//
//  ViewController.swift
//  OnBrix_iOS
//
//  Created by rrobbie on 2023/02/13.
//

import UIKit
import WebKit
import FileBrowser
import PhotosUI
import Firebase
import FBSDKCoreKit

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
        
    enum AppStoreLinkTag:Int {
        case app_link_isp, app_link_bank
    }
    
    var button:UIButton?
    
    let messageHandlerName = "callbackHandler"
    
}

extension ViewController {
    
    //  ===
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialize(webView: self.webView)
        
        let url = URL(string: Constants.EndPoint)
        let request = URLRequest(url: url!)
        self.webView.load(request)
        self.webView.allowsBackForwardNavigationGestures = true
        
        checkAlbumPermission()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
     override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
         if keyPath == #keyPath(WKWebView.url) {
             guard let url = self.webView.url?.absoluteString else {
                 return
             }
         }
     }
    
    func initialize(webView:WKWebView){
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.white
        
        setWKWebViewConfigration(webview: webView)
        
        webView.configuration.userContentController.add(self, name: "ios")
        
        webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
            if let userAgent = result as? String{
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
                webView.customUserAgent = userAgent.appending(Constants.addedUserAgent).appending(appVersion)
            }
        }
    }
    
    @objc func didSubDataPush(){
        if let url = Constants.AppDelegate?.getData(key: "url") as? String{
            
            if url != ""{
                let url = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
                let request:URLRequest = URLRequest(url: url)
                
                self.webView.load(request)
                // Swift swiping gestures
                self.webView.allowsBackForwardNavigationGestures = true
                
                Constants.AppDelegate?.setData(data: "", key: "url")
            }
        }
    }
    
    @objc func didSubDataPushProc(){
        let time = DispatchTime.now() + .milliseconds(200)
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.didSubDataPush()
        }
    }
    
    func checkAlbumPermission(){
        PHPhotoLibrary.requestAuthorization( { status in
            switch status{
            case .authorized:
                print("Album: 권한 허용")
            case .denied:
                print("Album: 권한 거부")
            case .restricted, .notDetermined:
                print("Album: 선택하지 않음")
            default:
                break
            }
        })
    }
}

extension ViewController: WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {

        preferences.preferredContentMode = .mobile

        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
        } else {
            
            if let url = navigationAction.request.url,
              url.scheme != "http" && url.scheme != "https" {
                UIApplication.shared.open(url, options: [:], completionHandler:{ (success) in
                  if !(success){
                    /*앱이 설치되어 있지 않을 때*/
                  }
                })
                decisionHandler(.cancel, preferences)
              } else {
                decisionHandler(.allow, preferences)
              }
        }
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        if let url = navigationAction.request.url,
          url.scheme != "http" && url.scheme != "https" {
            UIApplication.shared.open(url, options: [:], completionHandler:{ (success) in
              if !(success){
                /*앱이 설치되어 있지 않을 때*/
              }
            })
            decisionHandler(.cancel)
          } else {
            decisionHandler(.allow)
          }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let urlResponse = navigationResponse.response as? HTTPURLResponse,
           let url = urlResponse.url,
           let allHeaderFields = urlResponse.allHeaderFields as? [String : String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
            HTTPCookieStorage.shared.setCookies(cookies , for: urlResponse.url!, mainDocumentURL: nil)

            if navigationResponse.canShowMIMEType {
                decisionHandler(.allow)
            } else {
                decisionHandler(.download)
            }
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,completionHandler: @escaping (String?) -> Void) {
        
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        let userController = WKUserContentController()
        
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController = userController
        
        let window = UIApplication.shared.windows.first
        let top = window?.safeAreaInsets.top
        let bottom = window?.safeAreaInsets.bottom
        
        let newWebView = WKWebView(frame: webView.frame, configuration: configuration)
        newWebView.load(navigationAction.request)
        newWebView.frame.origin.y = top ?? 0
        self.initialize(webView: newWebView)
        webView.addSubview(newWebView)
        return newWebView
    }
    
    @objc func buttonAction(sender:UIButton!){
        self.DeleteWebView()
        sender.removeFromSuperview()
    }
    
    func DeleteWebView(){
        if self.button != nil{
            self.button?.removeFromSuperview()
            self.button = nil
        }
        for subWebView in self.webView.subviews{
            if subWebView is WKWebView{
                subWebView.removeFromSuperview()
            }
        }
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        self.button?.removeFromSuperview()
        webView.removeFromSuperview()
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // 중복적으로 리로드가 일어나지 않도록 처리 필요.
        webView.reload()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString{
            if( url.contains(Constants.EndPoint) && Constants.isFirst ) {
                Constants.isFirst = false
                self.webView.evaluateJavaScript("appVersionRequest('ios')", completionHandler: nil)
                print("appVersionRequest")
            }
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("userContentController : ", message.body )

        if let json = message.body as? NSDictionary{
                        
            let key = json.object(forKey: "func") as? String
                        
            if(key == "externalBrowser") {
                let value = json.object(forKey: "url") as? String
                UIApplication.shared.open(URL(string: value!)!)
            } else if(key == "getToken") {
                self.webView.evaluateJavaScript("appBridgeDeviceToken('ios','\(Constants.token)')", completionHandler: nil)
            } else if(key == "getVersion") {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
                self.webView.evaluateJavaScript("appBridgeVersion('\(version)')", completionHandler: nil)
            } else if(key == "checkAppVersion") {
                guard let version = json.object(forKey: "version") as? String,
                      let minVersion = json.object(forKey: "minVersion") as? String,
                      let message = json.object(forKey: "message") as? String else { return }
                checkAppVersion(appStoreVersion: version, minVersion: minVersion, message: message)
            } else if(key == "downloadFile") {
                let url = json.object(forKey: "url") as! String
                let format = json.object(forKey: "format") as! String

                download(url: url, filename: "\(Date().timeIntervalSince1970).\(format)", callBackFuncName: "")
            } else if(key == "transTrackingGA") {
                let name = json.object(forKey: "name") as? String
                let id = json.object(forKey: "id") as? String
                let quantity = json.object(forKey: "quantity") as? String
                let currency = json.object(forKey: "currency") as? String
                let coupon = json.object(forKey: "coupon") as? String

                print("transTrackingGA > name : \(name), id : \(id), quantity : \(quantity), currency : \(currency), coupon : \(coupon)")

                if let name = name {
                    Analytics.logEvent(name, parameters: [
                      AnalyticsParameterItemID: id ?? "",
                      AnalyticsParameterQuantity: quantity ?? "",
                      //    AnalyticsParameterContentType: "product",
                      AnalyticsParameterCurrency: currency ?? "",
                      AnalyticsParameterCoupon: coupon ?? ""
                    ])
                }

            } else if(key == "transTrackingFB") {
                let name = json.object(forKey: "name") as? String
                let id = json.object(forKey: "id") as? String
                let items = json.object(forKey: "items") as? String
                let currency = json.object(forKey: "currency") as? String
                
                let params: [String : Any] =
                [ AppEvents.ParameterName.contentID.rawValue: id ?? "",
                  //    AppEvents.ParameterName.contentType.rawValue: "product",
                  AppEvents.ParameterName.numItems.rawValue: items ?? "",
                  AppEvents.ParameterName.currency.rawValue: currency ?? ""
                ]
                
                AppEvents.logEvent(AppEvents.Name(rawValue: name ?? ""), parameters: params)
                
                
                print("transTrackingFB > name : \(name), id : \(id), items : \(items), currency : \(currency) ")
            }
        }
    }
        
    func openAppStore() {
        let appId = "6445912643"
        let url = "itms-apps://itunes.apple.com/app/apple-store/" + appId;
        if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(0)
            }
        }
    }
    
    func checkAppVersion(appStoreVersion: String, minVersion: String, message: String = "") {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String

        let isMin: ComparisonResult = version.versionCompare(minVersion)
        let isAppStoreVersion: ComparisonResult = version.versionCompare(appStoreVersion)
        
        let alert = UIAlertController(title: "버전 업데이트", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "네", style: .default, handler: { (UIAlertAction) in
            self.openAppStore()
        }))
        
        if(isMin == .orderedAscending) {
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        } else if(isAppStoreVersion == .orderedAscending) {
            alert.addAction(UIAlertAction(title: "아니오", style: .default, handler: { (UIAlertAction) in
            }))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        print("version ; ", version, isAppStoreVersion, isMin)
    }

    func showAlertViewWithMessage(msg:String, tagNum:AppStoreLinkTag){
        let alert = UIAlertController(title: "알림", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            var URLString = ""
            if tagNum == .app_link_isp{
                URLString = "http://itunes.apple.com/kr/app/id369125087?mt=8"
            }else{
                URLString = "http://itunes.apple.com/us/app/id398456030?mt=8"
            }
            UIApplication.shared.open(URL(string: URLString)!, options: [UIApplication.OpenExternalURLOptionsKey : Any](), completionHandler: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func download(url:String, filename:String, callBackFuncName:String){
        // Create destination URL
        let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        let destinationFileUrl = documentsUrl.appendingPathComponent(filename)
        
        //Create URL to the source file you want to download
        guard let fileURL = URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else{
            return
        }
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if ((response as? HTTPURLResponse)?.statusCode) != nil {
                    DispatchQueue.main.async {
                        let fileBrowser = FileBrowser()
                        self.present(fileBrowser, animated: true, completion: nil)
 
                        self.webView.evaluateJavaScript("\(callBackFuncName)()", completionHandler: nil)
                    }
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                } catch (_) {
                    DispatchQueue.main.async {
                        self.showAlert("파일다운로드중 오류가 발생하였습니다.", "", "확인")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert("파일다운로드중 오류가 발생하였습니다.", "", "확인")
                }
            }
        }
        
        task.resume()
    }
    
    typealias action = (UIAlertAction)->Void
    func showAlert(_ title:String, _ message:String, _ ok:String? = nil, _ cancel:String? = nil, _ okAction:action? = nil, _ cancelAction:action? = nil, _ style:UIAlertController.Style = .alert){
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        
        if let ok = ok{
            alert.addAction(UIAlertAction(title: ok, style: .default, handler: okAction))
        }
        
        if let cancel = cancel{
            alert.addAction(UIAlertAction(title: cancel, style: .default, handler: cancelAction))
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

//plist파일을 생성한다.
var plistURL : URL {
    let documentDirectoryURL =  try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    return documentDirectoryURL.appendingPathComponent("dictionary.plist")
}

func savePropertyList(_ plist: Any) throws{
    let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try plistData.write(to: plistURL)
}

func loadPropertyList() throws -> [String:String]{
    //plist정보가 빈값으면 빈값으로 리턴된다 (:)
    guard let data = try? Data(contentsOf: plistURL) else {
        return [String:String]()
    }
    
    //plist정보가 있으면 리턴한다.
    guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String:String] else {
        return [String:String]()
    }
    return plist
}

func clean() {
    HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
    
    WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
        records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            print("[WebCacheCleaner] Record \(record) deleted")
        }
    }
}

private func clearDocumentsDirectory() {
    let fileManager = FileManager.default
    guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    
    let items = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
    items?.forEach { item in
        try? fileManager.removeItem(at: item)
    }
}

func findKeyForValue(value: String, dictionary: [String: [String]]) ->String?{
    for (key, array) in dictionary{
        if (array.contains(value)){
            return key
        }
    }
    return nil
}

func setWKWebViewConfigration(webview: WKWebView) {
    let wkUserContentController = WKUserContentController()
    let wkWebviewPreference = WKPreferences()
    let wKWebpagePreferences = WKWebpagePreferences()
    wKWebpagePreferences.allowsContentJavaScript = true
    
    //Message 핸들러 설정
    webview.configuration.userContentController = wkUserContentController
    webview.configuration.suppressesIncrementalRendering = false
    webview.configuration.selectionGranularity = .dynamic
    webview.configuration.allowsInlineMediaPlayback = true

    webview.configuration.allowsAirPlayForMediaPlayback = false
    webview.configuration.allowsPictureInPictureMediaPlayback = true
    webview.configuration.websiteDataStore = WKWebsiteDataStore.default()
    webview.configuration.mediaTypesRequiringUserActionForPlayback = .all
    
    // WKPreference 셋팅
    wkWebviewPreference.minimumFontSize = 0 // 기본값 = 0
    wkWebviewPreference.javaScriptCanOpenWindowsAutomatically = true // 기본값 = false
    wkWebviewPreference.javaScriptEnabled = true // 기본값 = true
    
    webview.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    webview.configuration.preferences = wkWebviewPreference
    
    // 나이스 인증 관련 설정 추가
    webview.translatesAutoresizingMaskIntoConstraints = false
    webview.scrollView.bounces = true
    webview.scrollView.showsHorizontalScrollIndicator = false
    webview.scrollView.scrollsToTop = true
    
}


