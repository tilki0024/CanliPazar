import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Universal Links (iOS) ve App Links (Android) için .well-known dosyalarını sunar.
 * canlipazar.net için apple-app-site-association ve assetlinks.json
 */
export const getWellKnown = functions.https.onRequest((req, res) => {
  const path = (req.path || "").toLowerCase();
  if (path.includes("assetlinks")) {
    res.set("Content-Type", "application/json");
    res.send(JSON.stringify([
      {
        relation: ["delegate_permission/common.handle_all_urls"],
        target: {
          namespace: "android_app",
          package_name: "com.canlipazar",
          sha256_cert_fingerprints: [
            process.env.ANDROID_SHA256_FINGERPRINT || "SHA256_FINGERPRINT_HERE"
          ]
        }
      }
    ]));
    return;
  }
  // apple-app-site-association (Content-Type: application/json kabul edilir)
  res.set("Content-Type", "application/json");
  res.send(JSON.stringify({
    applinks: {
      apps: [],
      details: [{
        appID: "TEAM_ID.com.canlipazar.app",
        paths: ["/ilan/*", "/animal/*", "/p/*"]
      }]
    },
    webcredentials: {
      apps: ["TEAM_ID.com.canlipazar.app"]
    }
  }));
});

/**
 * İlan detay sayfası için server-side rendering
 * Open Graph meta tag'leri ile sosyal medya önizlemesi
 * 
 * Path: https://canlipazar.net/ilan/{ilanId}
 */
export const getIlanPage = functions.https.onRequest(async (req, res) => {
  try {
    // URL'den ilan ID'sini çıkar
    const path = req.path;
    const pathSegments = path.split('/').filter(s => s.length > 0);
    
    let ilanId: string | null = null;
    
    // /ilan/{ilanId} formatı
    if (pathSegments.length >= 2 && pathSegments[0] === 'ilan') {
      ilanId = pathSegments[1];
    }
    // /animal/{ilanId} formatı (geriye dönük uyumluluk)
    else if (pathSegments.length >= 2 && pathSegments[0] === 'animal') {
      ilanId = pathSegments[1];
    }
    // Query parameter
    else {
      ilanId = req.query.id as string || null;
    }
    
    if (!ilanId) {
      // İlan ID yoksa varsayılan sayfayı göster
      res.set('Content-Type', 'text/html; charset=utf-8');
      res.send(getDefaultHTML());
      return;
    }
    
    console.log(`📄 İlan sayfası oluşturuluyor: ${ilanId}`);
    
    // Firestore'dan ilan bilgilerini al
    const ilanDoc = await admin.firestore()
      .collection('animals')
      .doc(ilanId)
      .get();
    
    if (!ilanDoc.exists) {
      console.log(`⚠️ İlan bulunamadı: ${ilanId}`);
      res.set('Content-Type', 'text/html; charset=utf-8');
      res.send(getDefaultHTML());
      return;
    }
    
    const ilanData = ilanDoc.data();
    
    // İlan bilgilerini formatla
    const ilanBaslik = ilanData?.animalBreed && ilanData.animalBreed.length > 0
      ? `${ilanData.animalBreed} - ${ilanData.animalSpecies || 'Hayvan'}`
      : ilanData?.animalSpecies || 'Hayvan İlanı';
    
    const ilanAciklama = ilanData?.description && ilanData.description.length > 0
      ? (ilanData.description.length > 150 
          ? ilanData.description.substring(0, 150) + '...'
          : ilanData.description)
      : `${ilanBaslik} - ${formatPrice(ilanData?.priceInTL || 0)} ₺`;
    
    const ilanResmi = ilanData?.photoUrls && ilanData.photoUrls.length > 0
      ? ilanData.photoUrls[0]
      : 'https://canlipazar.net/default-image.jpg';
    
    const ilanUrl = `https://canlipazar.net/ilan/${ilanId}`;
    
    // HTML oluştur
    const html = generateHTML({
      ilanId,
      ilanBaslik,
      ilanAciklama,
      ilanResmi,
      ilanUrl,
    });
    
    // Content-Type header'ı ayarla
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
    
  } catch (error: any) {
    console.error('❌ İlan sayfası oluşturma hatası:', error);
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.send(getDefaultHTML());
  }
});

/**
 * Fiyat formatla
 */
function formatPrice(price: number): string {
  return new Intl.NumberFormat('tr-TR').format(price);
}

/**
 * HTML oluştur
 */
function generateHTML(data: {
  ilanId: string;
  ilanBaslik: string;
  ilanAciklama: string;
  ilanResmi: string;
  ilanUrl: string;
}): string {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  
  <!-- KRİTİK: Open Graph Meta Tags - Sosyal Medya Önizlemesi -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="${data.ilanUrl}">
  <meta property="og:title" content="${escapeHtml(data.ilanBaslik)}">
  <meta property="og:description" content="${escapeHtml(data.ilanAciklama)}">
  <meta property="og:image" content="${data.ilanResmi}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:site_name" content="CanlıPazar">
  <meta property="og:locale" content="tr_TR">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:url" content="${data.ilanUrl}">
  <meta name="twitter:title" content="${escapeHtml(data.ilanBaslik)}">
  <meta name="twitter:description" content="${escapeHtml(data.ilanAciklama)}">
  <meta name="twitter:image" content="${data.ilanResmi}">
  
  <!-- iOS Universal Links -->
  <meta name="apple-itunes-app" content="app-id=6476391295">
  
  <!-- Android App Links -->
  <link rel="alternate" href="android-app://com.canlipazar/https/canlipazar.net/ilan/${data.ilanId}">
  
  <!-- Canonical URL -->
  <link rel="canonical" href="${data.ilanUrl}">
  
  <title>${escapeHtml(data.ilanBaslik)} - CanlıPazar</title>
  <meta name="description" content="${escapeHtml(data.ilanAciklama)}">
  
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background: linear-gradient(135deg, #2E7D32 0%, #8BC34A 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    
    .container {
      background: white;
      max-width: 480px;
      width: 100%;
      border-radius: 20px;
      box-shadow: 0 12px 40px rgba(0,0,0,0.12);
      overflow: hidden;
    }
    
    .ilan-ozet {
      padding: 0;
      text-align: center;
    }
    
    .ilan-img {
      width: 100%;
      height: 260px;
      object-fit: cover;
      background: #f5f5f5;
    }
    
    .ilan-body {
      padding: 24px 20px;
    }
    
    .ilan-baslik {
      font-size: 20px;
      font-weight: 700;
      color: #1a1a1a;
      margin-bottom: 8px;
      line-height: 1.3;
    }
    
    .ilan-aciklama {
      font-size: 14px;
      color: rgba(0,0,0,0.6);
      line-height: 1.5;
      margin-bottom: 24px;
    }
    
    .btn-ac {
      display: inline-block;
      width: 100%;
      padding: 18px 24px;
      margin: 0 0 12px;
      background: #2E7D32;
      color: white !important;
      text-decoration: none;
      border-radius: 12px;
      font-weight: 600;
      font-size: 17px;
      transition: background 0.2s;
      border: none;
      cursor: pointer;
    }
    
    .btn-ac:hover {
      background: #1B5E20;
    }
    
    .store-buttons {
      display: none;
      padding: 20px 20px 28px;
      border-top: 1px solid #eee;
    }
    
    .store-buttons.show {
      display: block;
    }
    
    .store-buttons p {
      font-size: 13px;
      color: rgba(0,0,0,0.5);
      margin-bottom: 16px;
    }
    
    .button {
      display: inline-block;
      width: 100%;
      max-width: 300px;
      padding: 14px 24px;
      margin: 6px 0;
      background: #2E7D32;
      color: white;
      text-decoration: none;
      border-radius: 10px;
      font-weight: 600;
      font-size: 15px;
      transition: background 0.3s;
    }
    
    .button:hover {
      background: #1B5E20;
    }
    
    .button.secondary {
      background: #8BC34A;
    }
    
    .button.secondary:hover {
      background: #689F38;
    }
    
    .brand {
      font-size: 12px;
      color: rgba(0,0,0,0.4);
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="ilan-ozet" id="ilanOzet">
      <img class="ilan-img" src="${data.ilanResmi}" alt="${escapeHtml(data.ilanBaslik)}">
      <div class="ilan-body">
        <h1 class="ilan-baslik">${escapeHtml(data.ilanBaslik)}</h1>
        <p class="ilan-aciklama">${escapeHtml(data.ilanAciklama)}</p>
        <a href="#" id="btnUygulamayiAc" class="btn-ac">Uygulamayı Aç</a>
      </div>
    </div>
    
    <div class="store-buttons" id="storeButtons">
      <p>Uygulama yüklü değilse aşağıdan indirin:</p>
      <a href="#" id="appStoreBtn" class="button">App Store'dan İndir</a>
      <a href="#" id="playStoreBtn" class="button secondary">Google Play'den İndir</a>
      <p class="brand">CanlıPazar – Hayvan Alım Satım</p>
    </div>
  </div>

  <script>
    (function() {
      const ilanId = '${data.ilanId}';
      const universalLink = 'https://canlipazar.net/ilan/' + ilanId;
      
      const userAgent = navigator.userAgent || navigator.vendor || window.opera;
      const isIOS = /iPad|iPhone|iPod/.test(userAgent) && !window.MSStream;
      const isAndroid = /android/i.test(userAgent);
      
      const iosAppStoreUrl = 'https://apps.apple.com/app/id6476391295';
      const androidPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.canlipazar';
      
      document.getElementById('appStoreBtn').href = iosAppStoreUrl;
      document.getElementById('playStoreBtn').href = androidPlayStoreUrl;
      
      function openApp() {
        window.location.href = universalLink;
        setTimeout(function() {
          if (!document.hidden) showStoreButtons();
        }, 2200);
      }
      
      function showStoreButtons() {
        document.getElementById('storeButtons').classList.add('show');
      }
      
      document.getElementById('btnUygulamayiAc').onclick = function(e) {
        e.preventDefault();
        openApp();
      };
      
      if (ilanId) {
        setTimeout(openApp, 400);
      } else {
        showStoreButtons();
      }
    })();
  </script>
</body>
</html>`;
}

/**
 * Varsayılan HTML
 */
function getDefaultHTML(): string {
  return generateHTML({
    ilanId: '',
    ilanBaslik: 'CanlıPazar - Hayvan Alım Satım Platformu',
    ilanAciklama: 'Büyükbaş ve küçükbaş hayvan alım satımı için güvenilir platform',
    ilanResmi: 'https://canlipazar.net/default-image.jpg',
    ilanUrl: 'https://canlipazar.net',
  });
}

/**
 * HTML escape
 */
function escapeHtml(text: string): string {
  const map: { [key: string]: string } = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return text.replace(/[&<>"']/g, (m) => map[m]);
}














