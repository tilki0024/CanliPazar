# Flutter Kurulum Sorunu - Çözüm Rehberi

## Sorun
Flutter komutu terminalde bulunamıyor. `.zshrc` dosyasında Flutter PATH'i tanımlı ama Flutter kurulu değil.

## Çözüm 1: Flutter'ı Kurun

### Adım 1: Flutter SDK'yı İndirin
```bash
cd ~/Desktop
git clone https://github.com/flutter/flutter.git -b stable
```

### Adım 2: PATH'i Güncelleyin
`.zshrc` dosyası zaten doğru görünüyor, ancak yeni bir terminal açmanız gerekebilir:

```bash
source ~/.zshrc
```

### Adım 3: Flutter'ı Doğrulayın
```bash
flutter doctor
```

## Çözüm 2: Mevcut Flutter Kurulumunu Bulun

Eğer Flutter başka bir yerde kuruluysa:

```bash
# Flutter'ı bulun
find ~ -name "flutter" -type f -executable 2>/dev/null | grep bin/flutter

# Bulduğunuz path'i .zshrc'ye ekleyin
# Örnek: /Users/mustafatilki/flutter/bin
export PATH="$PATH:/Users/mustafatilki/flutter/bin"
```

## Çözüm 3: FVM (Flutter Version Manager) Kullanın

FVM kullanıyorsanız:

```bash
# FVM kurulumu
brew tap leoafarias/fvm
brew install fvm

# Flutter kurulumu
fvm install stable
fvm use stable

# PATH'i güncelleyin
export PATH="$PATH:$HOME/fvm/default/bin"
```

## Çözüm 4: Homebrew ile Kurun

```bash
# Homebrew ile Flutter kurulumu
brew install --cask flutter

# PATH kontrolü
which flutter
```

## Hızlı Test

Kurulumdan sonra:

```bash
# Terminal'i yeniden başlatın veya
source ~/.zshrc

# Flutter'ı test edin
flutter --version
flutter doctor
```

## Projeyi Çalıştırma

Flutter kurulduktan sonra:

```bash
cd ~/Desktop/CanliPazar-main
flutter clean
flutter pub get
flutter run
```

## Not

Eğer Flutter zaten kuruluysa ama PATH'te değilse, `.zshrc` dosyasını güncelleyin:

```bash
# .zshrc dosyasını düzenleyin
nano ~/.zshrc

# Flutter PATH'ini ekleyin (gerçek path'inizi kullanın)
export PATH="$PATH:/path/to/flutter/bin"

# Kaydedin ve terminal'i yeniden başlatın
source ~/.zshrc
```





