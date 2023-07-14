//
//  Constants.swift
//  OnBrix_iOS
//
//  Created by rrobbie on 2023/02/13.
//

import Foundation

class Constants: NSObject {
        
    //"https://www.onbrix.co.kr"
    //"https://dev.onbrix.co.kr"
    static var EndPoint:String = "https://www.onbrix.co.kr"

    static var token:String = ""

    static var AppDelegate:AppDelegate?
    
    static var isPush:Bool = true

    static var isFirst:Bool = true

    static var addedUserAgent:String = "&app=onbrix&&os=ios&appVersion="
    
}

