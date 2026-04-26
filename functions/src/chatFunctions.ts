/**
 * Sohbet Sistemi Cloud Functions
 * Firestore yapısını otomatik günceller
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Yeni mesaj eklendiğinde sohbet bilgilerini güncelle
 * users/{userId}/chats/{chatId}/messages/{messageId} yapısı için
 */
export const onMessageCreated = functions.firestore
    .document("users/{userId}/chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const messageData = snap.data();
      const userId = context.params.userId;
      const chatId = context.params.chatId;
      const messageId = context.params.messageId;

      console.log(`📨 Yeni mesaj: ${messageId} - Chat: ${chatId} - User: ${userId}`);

      const senderId = messageData.senderId || "";
      const receiverId = messageData.receiverId || "";
      const text = messageData.text || "";
      const timestamp = messageData.timestamp || admin.firestore.FieldValue.serverTimestamp();

      // Sohbet bilgilerini güncelle
      const chatRef = admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("chats")
          .doc(chatId);

      const updateData: any = {
        lastMessage: text,
        lastMessageTime: timestamp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Eğer bu kullanıcı alıcıysa, okunmamış mesaj sayısını artır
      if (userId === receiverId && senderId !== receiverId) {
        updateData.unreadCount = admin.firestore.FieldValue.increment(1);
      }

      // Silinmiş sohbeti geri getir
      updateData.deletedBy = admin.firestore.FieldValue.arrayRemove(userId);

      await chatRef.set(updateData, { merge: true });

      console.log(`✅ Sohbet güncellendi: ${chatId} - User: ${userId}`);

      // Karşı tarafın sohbetini de güncelle
      const otherUserId = userId === senderId ? receiverId : senderId;
      const otherChatRef = admin.firestore()
          .collection("users")
          .doc(otherUserId)
          .collection("chats")
          .doc(chatId);

      const otherUpdateData: any = {
        lastMessage: text,
        lastMessageTime: timestamp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedBy: admin.firestore.FieldValue.arrayRemove(otherUserId),
      };

      // Eğer bu kullanıcı gönderen ise, karşı tarafta okunmamış mesaj sayısını artır
      if (userId === senderId) {
        otherUpdateData.unreadCount = admin.firestore.FieldValue.increment(1);
      }

      await otherChatRef.set(otherUpdateData, { merge: true });

      console.log(`✅ Karşı tarafın sohbeti güncellendi: ${chatId} - User: ${otherUserId}`);

      // Push bildirimi gönder (mevcut onMessageCreated function'ını kullan)
      // Bu kısım mevcut bildirim sistemini kullanır

      return null;
    });

/**
 * Mesaj okundu olarak işaretlendiğinde unreadCount'u güncelle
 */
export const onMessageRead = functions.firestore
    .document("users/{userId}/chats/{chatId}/messages/{messageId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const chatId = context.params.chatId;

      // Mesaj okundu olarak işaretlendi mi?
      if (!beforeData.isRead && afterData.isRead) {
        const chatRef = admin.firestore()
            .collection("users")
            .doc(userId)
            .collection("chats")
            .doc(chatId);

        await chatRef.update({
          unreadCount: admin.firestore.FieldValue.increment(-1),
        });

        console.log(`✅ Okunmamış mesaj sayısı azaltıldı: ${chatId} - User: ${userId}`);
      }

      return null;
    });












