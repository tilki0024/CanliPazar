import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Firebase Dynamic Link oluştur
 * 
 * NOT: Firebase Dynamic Links artık deprecated olduğu için,
 * bu fonksiyon App Links ve kısa URL servisleri kullanır
 */
export const createDynamicLink = functions.https.onCall(async (data, context) => {
    try {
        const {
            deepLink,
            androidPackageName,
            iosBundleId,
            iosAppStoreId,
            title,
            description,
            imageUrl,
        } = data;

        if (!deepLink) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "deepLink is required"
            );
        }

        // Firebase Dynamic Links REST API kullanarak link oluştur
        // NOT: Bu API artık deprecated, ancak mevcut projeler için çalışmaya devam ediyor
        const dynamicLinksDomain = "https://canlipazar.page.link";
        const apiKey = functions.config().firebase?.apiKey || process.env.FIREBASE_API_KEY;

        if (!apiKey) {
            console.warn("⚠️ Firebase API key bulunamadı, fallback link döndürülüyor");
            return {
                shortLink: deepLink,
                longLink: deepLink,
            };
        }

        // Dynamic Link oluşturma isteği
        const requestBody = {
            dynamicLinkInfo: {
                domainUriPrefix: dynamicLinksDomain,
                link: deepLink,
                androidInfo: {
                    androidPackageName: androidPackageName || "com.canlipazar.app",
                },
                iosInfo: {
                    iosBundleId: iosBundleId || "com.canlipazar.app",
                    iosAppStoreId: iosAppStoreId || "123456789",
                },
                socialMetaTagInfo: {
                    socialTitle: title || "CanlıPazar İlanı",
                    socialDescription: description || "Hayvan alım satımı platformu",
                    socialImageLink: imageUrl || "https://canlipazar.net/default-image.jpg",
                },
            },
            suffix: {
                option: "SHORT",
            },
        };

        // Firebase Dynamic Links REST API çağrısı
        const response = await fetch(
            `https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=${apiKey}`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(requestBody),
            }
        );

        if (!response.ok) {
            const errorText = await response.text();
            console.error("❌ Dynamic Link API hatası:", errorText);
            // Hata durumunda fallback link döndür
            return {
                shortLink: deepLink,
                longLink: deepLink,
            };
        }

        const result = await response.json();
        const shortLink = result.shortLink || deepLink;
        const longLink = result.previewLink || deepLink;

        console.log("✅ Dynamic Link oluşturuldu:", shortLink);

        return {
            shortLink: shortLink,
            longLink: longLink,
        };
    } catch (error: any) {
        console.error("❌ Dynamic Link oluşturma hatası:", error);
        // Hata durumunda fallback link döndür
        return {
            shortLink: data.deepLink || "https://canlipazar.net",
            longLink: data.deepLink || "https://canlipazar.net",
        };
    }
});






























