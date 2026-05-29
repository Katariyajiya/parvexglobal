import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SampleAdMobBanner extends StatefulWidget {
  const SampleAdMobBanner({Key? key}) : super(key: key);

  @override
  State<SampleAdMobBanner> createState() => _SampleAdMobBannerState();
}

class _SampleAdMobBannerState extends State<SampleAdMobBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We use didChangeDependencies instead of initState because we
    // need access to MediaQuery (the screen width) before loading the ad.
    if (!_isLoading && !_isLoaded) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Get the screen width
    final viewWidth = MediaQuery.of(context).size.width.truncate();

    // 2. Let AdMob calculate the optimal, most compact adaptive size
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(viewWidth);

    if (size == null) {
      debugPrint('Unable to calculate adaptive banner size.');
      return;
    }

    // 3. Request the ad using the newly calculated adaptive size
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          setState(() {
            _isLoading = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: double.infinity,        // stretch full width
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Returns an empty, zero-size widget while loading to prevent
    // blocking any space unnecessarily before the ad is ready.
    return const SizedBox.shrink();
  }
}