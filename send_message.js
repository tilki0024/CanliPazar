// Firebase Admin SDK ile mesaj gönderme scripti
// Kullanım: node send_message.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Firebase Admin SDK key dosyası gerekli

// Firebase Admin'i başlat
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function sendTestMessage() {
  const senderId = 'TEST_SENDER_' + Date.now();
  const receiverId = 'CtBc8p5lhaSgQDv3oI9jfUwMAmS2';
  
  // Conversation ID oluştur
  const conversationId = senderId.localeCompare(receiverId) <= 0
    ? `${senderId}-${receiverId}`
    : `${receiverId}-${senderId}`;
  
  const messageText = 'Merhaba! Bu otomatik bir test mesajıdır.';
  
  console.log('📤 Mesaj gönderiliyor...');
  console.log('Gönderen:', senderId);
  console.log('Alıcı:', receiverId);
  console.log('Mesaj:', messageText);
  console.log('Conversation ID:', conversationId);
  
  try {
    // Mesajı conversations koleksiyonuna ekle
    const messageRef = await db.collection('conversations').add({
      text: messageText,
      sender: senderId,
      recipient: receiverId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      messagesId: conversationId,
      users: [senderId, receiverId],
      postId: '',
      isRead: false,
      senderName: 'Test Kullanıcı',
      notificationTitle: 'Test Kullanıcı',
      notificationBody: messageText,
    });
    
    // Alıcının unreadMessageCount'unu artır
    await db.collection('users').doc(receiverId).update({
      unreadMessageCount: admin.firestore.FieldValue.increment(1),
    });
    
    console.log('✅ Mesaj başarıyla gönderildi!');
    console.log('Message ID:', messageRef.id);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Hata:', error);
    process.exit(1);
  }
}

sendTestMessage();































