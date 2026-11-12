import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kowopay/utils/secure_logger.dart';

class AdService {
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // test banner
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // test banner
    }
    return '';
  }

  BannerAd? createBannerAd() {
    final String unitId = bannerAdUnitId;
    if (unitId.isEmpty) return null;

    return BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => SecureLog.debug('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          SecureLog.warn('Banner ad failed to load');
          ad.dispose();
        },
      ),
    );
  }
}
