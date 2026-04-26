import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/safe_fonts.dart';

class TermsOfServicePage extends StatelessWidget {
  final String termsOfServiceUrl = "https://canlipazar.com/terms-of-service";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Text(
          'CanlıPazar Kullanım Şartları',
          style: SafeFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CanlıPazar Kullanım Şartları',
                    style: SafeFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son güncelleme: ${DateTime.now().year}',
                    style: SafeFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('1. Şartların Kabulü'),
                  _buildText(
                    'CanlıPazar uygulamasını kullanarak bu kullanım şartlarını ve gizlilik politikamızı kabul etmiş sayılırsınız. Bu şartların herhangi bir kısmını kabul etmiyorsanız, uygulamamızı kullanmamalısınız.',
                    isFirst: true,
                    isLast: false,
                    hasIcon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF4CAF50),
                  ),
                  _buildSectionTitle('2. Hizmet Tanımı'),
                  _buildText(
                    'CanlıPazar, büyükbaş ve küçükbaş hayvan alım satımı için güvenli bir platform sağlar. Hizmetlerimiz:\n\n'
                    '• Hayvan ilanı yayınlama ve görüntüleme\n'
                    '• Kullanıcılar arası mesajlaşma\n'
                    '• Konum bazlı arama ve filtreleme\n'
                    '• Güvenli ödeme altyapısı\n'
                    '• Veteriner doğrulama sistemi',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.pets,
                    iconColor: const Color(0xFF795548),
                  ),
                  _buildSectionTitle('3. Kullanıcı Sorumlulukları'),
                  _buildText(
                    'Uygulamamızı kullanırken:\n\n'
                    '• Doğru ve güncel bilgi sağlamalısınız\n'
                    '• Hayvan sağlığı ve refahını önemsemelisiniz\n'
                    '• Yasal düzenlemelere uymalısınız\n'
                    '• Diğer kullanıcılara saygılı olmalısınız\n'
                    '• Platform güvenliğini korumalısınız',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.person_outline,
                    iconColor: const Color(0xFF2196F3),
                  ),
                  _buildSectionTitle('4. Yasaklı İçerik ve Davranışlar'),
                  _buildText(
                    'Aşağıdaki içerik ve davranışlar kesinlikle yasaktır:\n\n'
                    '• Sahte veya yanıltıcı hayvan ilanları\n'
                    '• Hasta veya sağlıksız hayvan satışı\n'
                    '• Taciz, tehdit veya saldırgan davranış\n'
                    '• Spam veya istenmeyen mesajlar\n'
                    '• Yasadışı hayvan ticareti\n'
                    '• Telif hakkı ihlali',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.block,
                    iconColor: const Color(0xFFE91E63),
                  ),
                  _buildSectionTitle('5. Hayvan Sağlığı ve Refahı'),
                  _buildText(
                    'CanlıPazar, hayvan sağlığı ve refahını önemsemektedir:\n\n'
                    '• Sadece sağlıklı hayvanlar satılabilir\n'
                    '• Veteriner raporu gereklidir\n'
                    '• Aşı kartları kontrol edilir\n'
                    '• Hayvan refahı standartları uygulanır\n'
                    '• Şüpheli durumlar raporlanır',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.favorite,
                    iconColor: const Color(0xFFFF5722),
                  ),
                  _buildSectionTitle('6. İçerik Moderasyonu'),
                  _buildText(
                    'Platform güvenliği için:\n\n'
                    '• Tüm ilanlar önceden incelenir\n'
                    '• Kullanıcı raporları değerlendirilir\n'
                    '• Şüpheli içerikler kaldırılır\n'
                    '• Kural ihlali yapan hesaplar kapatılır\n'
                    '• Sürekli güvenlik denetimi yapılır',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.security,
                    iconColor: const Color(0xFF607D8B),
                  ),
                  _buildSectionTitle('7. Ödeme ve İşlem Güvenliği'),
                  _buildText(
                    'CanlıPazar güvenli ödeme altyapısı sağlar:\n\n'
                    '• Şifreli ödeme işlemleri\n'
                    '• Güvenli para transferi\n'
                    '• İşlem kayıtları tutulur\n'
                    '• Anlaşmazlık çözümü\n'
                    '• Para iade garantisi',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.payment,
                    iconColor: const Color(0xFF00BCD4),
                  ),
                  _buildSectionTitle('8. Fikri Mülkiyet'),
                  _buildText(
                    'CanlıPazar platformu ve içeriği:\n\n'
                    '• Telif hakkı ile korunmaktadır\n'
                    '• Ticari marka hakları saklıdır\n'
                    '• Kopyalama ve dağıtım yasaktır\n'
                    '• Tersine mühendislik yasaktır\n'
                    '• Lisans ihlali cezalandırılır',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.copyright,
                    iconColor: const Color(0xFF9C27B0),
                  ),
                  _buildSectionTitle('9. Sorumluluk Sınırları'),
                  _buildText(
                    'CanlıPazar:\n\n'
                    '• Kullanıcılar arası anlaşmalardan sorumlu değildir\n'
                    '• Hayvan sağlığı garantisi vermez\n'
                    '• Üçüncü taraf hizmetlerden sorumlu değildir\n'
                    '• Teknik aksaklıklardan sorumlu değildir\n'
                    '• Maksimum yasal sorumluluk sınırları geçerlidir',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.gavel,
                    iconColor: const Color(0xFF795548),
                  ),
                  _buildSectionTitle('10. Hesap Sonlandırma'),
                  _buildText(
                    'Aşağıdaki durumlarda hesabınız kapatılabilir:\n\n'
                    '• Kural ihlali yapmanız\n'
                    '• Sahte bilgi vermeniz\n'
                    '• Platform güvenliğini tehdit etmeniz\n'
                    '• Diğer kullanıcıları rahatsız etmeniz\n'
                    '• Yasal düzenlemelere aykırı davranmanız',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.person_off,
                    iconColor: const Color(0xFFE91E63),
                  ),
                  _buildSectionTitle('11. Şartların Değişikliği'),
                  _buildText(
                    'Bu kullanım şartlarını zaman zaman güncelleyebiliriz. Önemli değişiklikler olduğunda sizi bilgilendireceğiz. Güncel şartlar her zaman uygulamamızda mevcut olacaktır.',
                    isFirst: false,
                    isLast: false,
                    hasIcon: Icons.update,
                    iconColor: const Color(0xFFFF9800),
                  ),
                  _buildSectionTitle('12. İletişim ve Destek'),
                  _buildText(
                    'Kullanım şartlarıyla ilgili sorularınız için:\n\n'
                    '📧 E-posta: destek.canlipazar@gmail.com\n'
                    '🌐 Web: www.canlipazar.net\n',
                    isFirst: false,
                    isLast: true,
                    hasIcon: Icons.support_agent,
                    iconColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Browser Button
            Center(
              child: Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    if (await canLaunch(termsOfServiceUrl)) {
                      await launch(termsOfServiceUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bağlantı açılamadı'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(
                    'Kullanım Şartlarını Tarayıcıda Aç',
                    style: SafeFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 24.0),
      child: Text(
        title,
        style: SafeFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20.0,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildText(
    String text, {
    bool isFirst = false,
    bool isLast = false,
    IconData? hasIcon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 8,
        bottom: isLast ? 0 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor?.withOpacity(0.1) ??
                    const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasIcon,
                color: iconColor ?? const Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: SafeFonts.poppins(
                fontSize: 15.0,
                color: const Color(0xFF495057),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
