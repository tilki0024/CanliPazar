//
//  NotificationManager.swift
//  CanlıPazar
//
//  Push Bildirim Yönetimi için NotificationManager
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Bildirim İzni İste
    
    /// Kullanıcıdan push bildirim izni ister
    func requestNotificationPermission(completion: @escaping (Bool, Error?) -> Void) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            
            let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
            
            center.requestAuthorization(options: options) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Bildirim izni verildi")
                        // İzin verildikten sonra cihaz token'ını al
                        UIApplication.shared.registerForRemoteNotifications()
                    } else {
                        print("❌ Bildirim izni reddedildi")
                    }
                    completion(granted, error)
                }
            }
        } else {
            // iOS 9 ve öncesi için
            let settings = UIUserNotificationSettings(
                types: [.alert, .badge, .sound],
                categories: nil
            )
            UIApplication.shared.registerUserNotificationSettings(settings)
            completion(true, nil)
        }
    }
    
    // MARK: - Badge Yönetimi
    
    /// Badge sayısını güncelle
    func updateBadge(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            print("📊 Badge güncellendi: \(count)")
        }
    }
    
    /// Badge'i sıfırla (uygulama açıldığında)
    func resetBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("🔄 Badge sıfırlandı")
        }
    }
    
    /// Badge'i artır
    func incrementBadge() {
        DispatchQueue.main.async {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = currentBadge + 1
            print("➕ Badge artırıldı: \(currentBadge + 1)")
        }
    }
    
    /// Badge'i azalt
    func decrementBadge() {
        DispatchQueue.main.async {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            if currentBadge > 0 {
                UIApplication.shared.applicationIconBadgeNumber = currentBadge - 1
                print("➖ Badge azaltıldı: \(currentBadge - 1)")
            }
        }
    }
    
    // MARK: - APNs Token Yönetimi
    
    /// APNs token'ını backend'e gönder
    func sendTokenToBackend(token: String, userId: String?) {
        guard let userId = userId else {
            print("⚠️ User ID bulunamadı, token gönderilemedi")
            return
        }
        
        // Backend'e token gönderme işlemi
        // Bu kısım backend API'nize göre özelleştirilmeli
        let url = URL(string: "https://your-backend-api.com/api/users/\(userId)/device-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "deviceToken": token,
            "platform": "ios",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Token gönderme hatası: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Token başarıyla backend'e gönderildi")
                } else {
                    print("⚠️ Token gönderme başarısız: HTTP \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // MARK: - Bildirim İçeriği Parse
    
    /// Bildirim içeriğinden badge sayısını çıkar
    func extractBadgeCount(from userInfo: [AnyHashable: Any]) -> Int? {
        // Önce aps içinden badge'i al
        if let aps = userInfo["aps"] as? [AnyHashable: Any] {
            if let badge = aps["badge"] as? Int {
                return badge
            } else if let badge = aps["badge"] as? NSNumber {
                return badge.intValue
            }
        }
        
        // Eğer aps'de yoksa, data içinden kontrol et
        if let unreadCount = userInfo["unreadCount"] as? String,
           let count = Int(unreadCount) {
            return count
        } else if let unreadCount = userInfo["unreadCount"] as? Int {
            return unreadCount
        }
        
        return nil
    }
    
    /// Bildirim içeriğinden mesaj bilgilerini çıkar
    func extractMessageInfo(from userInfo: [AnyHashable: Any]) -> (title: String?, body: String?, senderId: String?, messageId: String?) {
        let title: String?
        let body: String?
        let senderId: String?
        let messageId: String?
        
        // Notification içinden
        if let aps = userInfo["aps"] as? [AnyHashable: Any],
           let alert = aps["alert"] as? [AnyHashable: Any] {
            title = alert["title"] as? String
            body = alert["body"] as? String
        } else {
            title = nil
            body = nil
        }
        
        // Data içinden
        senderId = userInfo["senderId"] as? String ?? userInfo["sender_id"] as? String
        messageId = userInfo["messageId"] as? String ?? userInfo["message_id"] as? String
        
        return (title, body, senderId, messageId)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Uygulama açıkken bildirim geldiğinde
    @available(iOS 10.0, *)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📱 Bildirim alındı (foreground): \(userInfo)")
        
        // Badge'i güncelle
        if let badgeCount = extractBadgeCount(from: userInfo) {
            updateBadge(count: badgeCount)
        }
        
        // Bildirimi göster (alert, sound, badge)
        completionHandler([.alert, .sound, .badge])
    }
    
    // Kullanıcı bildirime tıkladığında
    @available(iOS 10.0, *)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Bildirime tıklandı: \(userInfo)")
        
        // Badge'i güncelle
        if let badgeCount = extractBadgeCount(from: userInfo) {
            updateBadge(count: badgeCount)
        }
        
        // Mesaj bilgilerini çıkar ve işle
        let messageInfo = extractMessageInfo(from: userInfo)
        
        // Mesaj sayfasına yönlendirme yapılabilir
        // Bu kısım Flutter tarafından handle edilebilir
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationTapped"),
            object: nil,
            userInfo: userInfo
        )
        
        completionHandler()
    }
}












