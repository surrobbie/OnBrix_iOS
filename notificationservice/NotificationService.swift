//
//  NotificationService.swift
//  notificationservice
//
//  Created by rrobbie on 2023/02/28.
//


import UserNotifications
import AVFoundation

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
                
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            
            if let imageURLString = bestAttemptContent.userInfo["image"] as? String {
                if let imagePath = DownloadManager.image(imageURLString) {
                    let imageURL = URL(fileURLWithPath: imagePath)
                    do {
                        let attach = try UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                        bestAttemptContent.attachments = [attach]
                    } catch {
                        print(error)
                    }
                }
            }
            
            let url = bestAttemptContent.userInfo["url"] as? String
            let linkUrl = bestAttemptContent.userInfo["linkUrl"] as? String            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
