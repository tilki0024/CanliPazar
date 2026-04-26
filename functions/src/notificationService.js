/**
 * APNs Push Bildirim Servisi
 * .p8 APNs anahtarı kullanarak push bildirim gönderir
 * 
 * Kullanım:
 * 1. Apple Developer Console'dan .p8 APNs anahtarını indirin
 * 2. Anahtarı functions/keys/ klasörüne koyun
 * 3. Aşağıdaki yapılandırmayı yapın
 */

const apn = require("apn");
const path = require("path");
const fs = require("fs");

class APNsNotificationService {
  constructor() {
    // APNs yapılandırması
    // .p8 dosyasının yolu
    const keyPath = path.join(__dirname, "../keys/AuthKey_94D623A8F4.p8");
    
    // Key ID (Apple Developer Console'dan alın)
    const keyId = "94D623A8F4";
    
    // Team ID (Apple Developer Console'dan alın)
    const teamId = "9W44LABURS";
    
    // Bundle ID - Xcode'dan kontrol edildi: com.canlipazar.app
    const bundleId = process.env.BUNDLE_ID || "com.canlipazar.app";
    
    // APNs provider oluştur
    const options = {
      token: {
        key: keyPath,
        keyId: keyId,
        teamId: teamId
      },
      production: process.env.NODE_ENV === "production" // Production için true, Development için false
    };
    
    this.apnProvider = new apn.Provider(options);
    this.bundleId = bundleId;
  }
  
  /**
   * Mesaj bildirimi gönder
   * @param {string} deviceToken - APNs device token
   * @param {Object} messageData - Mesaj verileri
   * @param {number} unreadCount - Okunmamış mesaj sayısı (badge için)
   */
  async sendMessageNotification(deviceToken, messageData, unreadCount = 0) {
    const notification = new apn.Notification();
    
    // Bildirim ayarları
    notification.alert = {
      title: messageData.title || "CanlıPazardan bir mesajınız var",
      body: messageData.body || messageData.text || "Yeni mesajınız var"
    };
    
    notification.sound = "default";
    notification.badge = unreadCount; // Badge sayısı
    notification.topic = this.bundleId;
    notification.contentAvailable = 1; // Silent push için
    notification.priority = 10; // Yüksek öncelik
    notification.pushType = "alert";
    
    // Custom data
    notification.payload = {
      type: "message",
      senderId: messageData.senderId,
      receiverId: messageData.receiverId,
      messageId: messageData.messageId,
      postId: messageData.postId || "",
      text: messageData.text || "",
      unreadCount: unreadCount.toString(),
    };
    
    // Bildirimi gönder
    try {
      const result = await this.apnProvider.send(notification, deviceToken);
      
      if (result.sent.length > 0) {
        console.log(`✅ Bildirim gönderildi: ${deviceToken.substring(0, 20)}...`);
        return { success: true, sent: result.sent };
      }
      
      if (result.failed.length > 0) {
        console.error(`❌ Bildirim gönderilemedi: ${result.failed[0].error}`);
        return { success: false, error: result.failed[0].error };
      }
      
      return { success: false, error: "Bilinmeyen hata" };
    } catch (error) {
      console.error(`❌ Bildirim gönderme hatası: ${error.message}`);
      return { success: false, error: error.message };
    }
  }
  
  /**
   * Toplu bildirim gönder (birden fazla cihaza)
   * @param {Array<string>} deviceTokens - APNs device token'ları
   * @param {Object} messageData - Mesaj verileri
   * @param {number} unreadCount - Okunmamış mesaj sayısı
   */
  async sendBulkNotification(deviceTokens, messageData, unreadCount = 0) {
    const notification = new apn.Notification();
    
    notification.alert = {
      title: messageData.title || "CanlıPazar",
      body: messageData.body || messageData.text || "Yeni bildiriminiz var"
    };
    
    notification.sound = "default";
    notification.badge = unreadCount;
    notification.topic = this.bundleId;
    notification.contentAvailable = 1;
    notification.priority = 10;
    notification.pushType = "alert";
    
    notification.payload = {
      type: messageData.type || "notification",
      ...messageData,
    };
    
    try {
      const result = await this.apnProvider.send(notification, deviceTokens);
      
      console.log(`✅ ${result.sent.length} bildirim gönderildi`);
      console.log(`❌ ${result.failed.length} bildirim başarısız`);
      
      return {
        success: true,
        sent: result.sent.length,
        failed: result.failed.length,
        details: result
      };
    } catch (error) {
      console.error(`❌ Toplu bildirim hatası: ${error.message}`);
      return { success: false, error: error.message };
    }
  }
  
  /**
   * APNs provider'ı kapat
   */
  shutdown() {
    this.apnProvider.shutdown();
  }
}

// Export singleton instance
let notificationServiceInstance = null;

function getNotificationService() {
  if (!notificationServiceInstance) {
    notificationServiceInstance = new APNsNotificationService();
  }
  return notificationServiceInstance;
}

module.exports = {
  APNsNotificationService,
  getNotificationService
};

/**
 * KULLANIM ÖRNEĞİ:
 * 
 * const { getNotificationService } = require("./notificationService");
 * 
 * const notificationService = getNotificationService();
 * 
 * // Tek bildirim
 * await notificationService.sendMessageNotification(
 *   "device_token_here",
 *   {
 *     title: "CanlıPazardan bir mesajınız var",
 *     body: "Merhaba, nasılsın?",
 *     senderId: "user123",
 *     receiverId: "user456",
 *     messageId: "msg789",
 *     text: "Merhaba, nasılsın?"
 *   },
 *   5 // 5 okunmamış mesaj
 * );
 * 
 * // Toplu bildirim
 * await notificationService.sendBulkNotification(
 *   ["token1", "token2", "token3"],
 *   {
 *     title: "Yeni ilan eklendi",
 *     body: "Yeni ilanlar eklendi, hemen göz at!",
 *     type: "new_animal_post"
 *   },
 *   0
 * );
 */








