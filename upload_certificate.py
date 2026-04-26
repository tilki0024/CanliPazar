#!/usr/bin/env python3
"""
Google Play Console API ile Certificate Yükleme Script'i
"""

import os
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# Gerekli bilgiler
SERVICE_ACCOUNT_FILE = 'service_account.json'  # Google Cloud'tan indirdiğiniz JSON dosyası
PACKAGE_NAME = 'com.canlipazar'  # Uygulama package adı
CERTIFICATE_FILE = 'android/upload_certificate_reset.pem'  # Certificate dosyası

def upload_certificate():
    """Play Console'a certificate yükler"""
    
    # Service account credentials yükle
    if not os.path.exists(SERVICE_ACCOUNT_FILE):
        print(f"❌ Hata: {SERVICE_ACCOUNT_FILE} dosyası bulunamadı!")
        print("   Google Cloud Console'dan service account JSON key'ini indirin.")
        return False
    
    # Certificate dosyasını oku
    if not os.path.exists(CERTIFICATE_FILE):
        print(f"❌ Hata: {CERTIFICATE_FILE} dosyası bulunamadı!")
        return False
    
    try:
        # Service account ile authenticate ol
        credentials = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=['https://www.googleapis.com/auth/androidpublisher']
        )
        
        # Play Console API client oluştur
        service = build('androidpublisher', 'v3', credentials=credentials)
        
        # Certificate dosyasını oku
        with open(CERTIFICATE_FILE, 'r') as f:
            certificate_content = f.read()
        
        # Certificate yükle
        print("📤 Certificate yükleniyor...")
        result = service.edits().uploadcertificate(
            packageName=PACKAGE_NAME,
            certificate=certificate_content
        ).execute()
        
        print("✅ Certificate başarıyla yüklendi!")
        print(f"   SHA-1: {result.get('sha1Fingerprint', 'N/A')}")
        return True
        
    except HttpError as error:
        print(f"❌ Hata: {error}")
        return False
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {e}")
        return False

if __name__ == '__main__':
    print("🔐 Google Play Console Certificate Yükleme")
    print("=" * 50)
    print()
    
    if upload_certificate():
        print()
        print("✅ İşlem tamamlandı!")
        print("   Şimdi AAB dosyasını Play Console'dan yükleyebilirsiniz.")
    else:
        print()
        print("❌ İşlem başarısız!")
        print("   Lütfen hataları kontrol edin.")
















