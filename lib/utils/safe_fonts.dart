import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Güvenli font helper - Google Fonts hata verirse fallback font kullanır
/// AssetManifest.json hatasını önlemek için Google Fonts doğrudan kullanılmaz
class SafeFonts {

  /// Poppins font'u güvenli şekilde döndürür
  /// Hata durumunda varsayılan font kullanır
  /// AssetManifest.json hatasını önlemek için Google Fonts kullanılmaz
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    // KRİTİK: Google Fonts kullanılmaz - AssetManifest.json hatasını önlemek için
    // Direkt varsayılan font döndür
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFamily: 'Roboto', // Varsayılan Material font
    );
  }
  
  /// Poppins font'u güvenli şekilde döndürür (withOpacity desteği ile)
  /// AssetManifest.json hatasını önlemek için Google Fonts kullanılmaz
  static TextStyle poppinsWithOpacity({
    double? fontSize,
    FontWeight? fontWeight,
    required Color baseColor,
    double opacity = 1.0,
    double? letterSpacing,
    double? height,
  }) {
    // KRİTİK: Google Fonts kullanılmaz - AssetManifest.json hatasını önlemek için
    // Direkt varsayılan font döndür
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: baseColor.withOpacity(opacity),
      letterSpacing: letterSpacing,
      height: height,
      fontFamily: 'Roboto', // Varsayılan Material font
    );
  }
  
  /// TextTheme oluşturur (ThemeData için)
  /// AssetManifest.json hatasını önlemek için Google Fonts kullanılmaz
  static TextTheme poppinsTextTheme({
    Color? color,
  }) {
    return TextTheme(
      displayLarge: poppins(fontSize: 57, fontWeight: FontWeight.w400, color: color),
      displayMedium: poppins(fontSize: 45, fontWeight: FontWeight.w400, color: color),
      displaySmall: poppins(fontSize: 36, fontWeight: FontWeight.w400, color: color),
      headlineLarge: poppins(fontSize: 32, fontWeight: FontWeight.w400, color: color),
      headlineMedium: poppins(fontSize: 28, fontWeight: FontWeight.w400, color: color),
      headlineSmall: poppins(fontSize: 24, fontWeight: FontWeight.w400, color: color),
      titleLarge: poppins(fontSize: 22, fontWeight: FontWeight.w500, color: color),
      titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w500, color: color),
      titleSmall: poppins(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyLarge: poppins(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: poppins(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: poppins(fontSize: 12, fontWeight: FontWeight.w400, color: color),
      labelLarge: poppins(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      labelMedium: poppins(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      labelSmall: poppins(fontSize: 11, fontWeight: FontWeight.w500, color: color),
    );
  }
}



