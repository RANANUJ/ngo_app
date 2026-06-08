import 'package:ngo_app/core/utils/network/network_utils.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Comprehensive caching service for images, data, and assets
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Memory caches
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, dynamic> _dataCache = {};
  final Map<String, ImageProvider> _imageProviderCache = {};
  
  // Preloaded asset images
  final Set<String> _preloadedAssets = {};
  
  // Cache directory
  Directory? _cacheDir;
  
  // Loading states
  bool _isInitialized = false;
  final Set<String> _loadingUrls = {};

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _cacheDir = await getTemporaryDirectory();
      _isInitialized = true;
      secureLog('CacheService initialized');
    } catch (e) {
      secureLog('Error initializing CacheService: $e');
    }
  }

  /// Preload all local asset images
  Future<void> preloadAssetImages(BuildContext context) async {
    final assets = [
      'assets/medical.png',
      'assets/accident.png',
      'assets/firefighter.png',
      'assets/disaster1.jpeg',
      'assets/safety.jpg',
      'assets/police.jpg',
      'assets/ambulance.png',
      'assets/fire.jpeg',
      'assets/women hepline.png',
      'assets/child.jpg',
      'assets/disaster.png',
      'assets/ngo_logo.png',
      'assets/volunteer.png',
      'assets/donor.png',
    ];

    final futures = <Future>[];
    
    for (final asset in assets) {
      if (!_preloadedAssets.contains(asset)) {
        futures.add(_preloadAsset(context, asset));
      }
    }

    await Future.wait(futures);
    secureLog('Preloaded ${_preloadedAssets.length} asset images');
  }

  Future<void> _preloadAsset(BuildContext context, String asset) async {
    try {
      await precacheImage(AssetImage(asset), context);
      _preloadedAssets.add(asset);
    } catch (e) {
      secureLog('Failed to preload asset: $asset');
    }
  }

  /// Get cached image from URL with automatic caching
  Future<Uint8List?> getNetworkImage(String url) async {
    if (url.isEmpty) return null;

    // Check memory cache first
    if (_imageCache.containsKey(url)) {
      return _imageCache[url];
    }

    // Check disk cache
    final cachedData = await _getDiskCache(url);
    if (cachedData != null) {
      _imageCache[url] = cachedData;
      return cachedData;
    }

    // Download and cache
    return await _downloadAndCache(url);
  }

  /// Preload network image in background
  Future<void> preloadNetworkImage(String url) async {
    if (url.isEmpty || _imageCache.containsKey(url) || _loadingUrls.contains(url)) {
      return;
    }

    _loadingUrls.add(url);
    
    try {
      await getNetworkImage(url);
    } finally {
      _loadingUrls.remove(url);
    }
  }

  /// Preload multiple images in parallel
  Future<void> preloadNetworkImages(List<String> urls) async {
    final validUrls = urls.where((url) => 
      url.isNotEmpty && 
      !_imageCache.containsKey(url) && 
      !_loadingUrls.contains(url)
    ).toList();

    if (validUrls.isEmpty) return;

    // Limit concurrent downloads to 5
    final chunks = _chunkList(validUrls, 5);
    for (final chunk in chunks) {
      await Future.wait(chunk.map((url) => preloadNetworkImage(url)));
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<Uint8List?> _downloadAndCache(String url) async {
    try {
      final response = await SecureHttp.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = response.bodyBytes;
        
        // Cache in memory
        _imageCache[url] = data;
        
        // Cache on disk
        await _setDiskCache(url, data);
        
        return data;
      }
    } catch (e) {
      secureLog('Error downloading image: $url - $e');
    }
    return null;
  }

  String _urlToFileName(String url) {
    final hash = url.hashCode.abs().toString();
    final extension = url.split('.').last.split('?').first;
    return '$hash.$extension';
  }

  Future<Uint8List?> _getDiskCache(String url) async {
    if (_cacheDir == null) return null;
    
    try {
      final file = File('${_cacheDir!.path}/img_cache/${_urlToFileName(url)}');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      secureLog('Error reading disk cache: $e');
    }
    return null;
  }

  Future<void> _setDiskCache(String url, Uint8List data) async {
    if (_cacheDir == null) return;
    
    try {
      final cacheFolder = Directory('${_cacheDir!.path}/img_cache');
      if (!await cacheFolder.exists()) {
        await cacheFolder.create(recursive: true);
      }
      
      final file = File('${cacheFolder.path}/${_urlToFileName(url)}');
      await file.writeAsBytes(data);
    } catch (e) {
      secureLog('Error writing disk cache: $e');
    }
  }

  /// Cache Firestore data
  void cacheData(String key, dynamic data) {
    _dataCache[key] = data;
  }

  /// Get cached Firestore data
  T? getCachedData<T>(String key) {
    return _dataCache[key] as T?;
  }

  /// Check if data is cached
  bool hasCache(String key) {
    return _dataCache.containsKey(key);
  }

  /// Clear specific cache
  void clearCache(String key) {
    _dataCache.remove(key);
    _imageCache.remove(key);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _imageCache.clear();
    _dataCache.clear();
    _imageProviderCache.clear();
    
    // Clear disk cache
    if (_cacheDir != null) {
      try {
        final cacheFolder = Directory('${_cacheDir!.path}/img_cache');
        if (await cacheFolder.exists()) {
          await cacheFolder.delete(recursive: true);
        }
      } catch (e) {
        secureLog('Error clearing disk cache: $e');
      }
    }
  }

  /// Get cache size in MB
  Future<double> getCacheSize() async {
    double size = 0;
    
    // Memory cache size
    for (final data in _imageCache.values) {
      size += data.length;
    }
    
    // Disk cache size
    if (_cacheDir != null) {
      try {
        final cacheFolder = Directory('${_cacheDir!.path}/img_cache');
        if (await cacheFolder.exists()) {
          await for (final file in cacheFolder.list()) {
            if (file is File) {
              size += await file.length();
            }
          }
        }
      } catch (e) {
        secureLog('Error calculating cache size: $e');
      }
    }
    
    return size / (1024 * 1024); // Convert to MB
  }
}

/// Cached network image widget with automatic caching
class CachedNetworkImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedNetworkImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<CachedNetworkImageWidget> createState() => _CachedNetworkImageWidgetState();
}

class _CachedNetworkImageWidgetState extends State<CachedNetworkImageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final data = await CacheService().getNetworkImage(widget.imageUrl);
    
    if (mounted) {
      setState(() {
        _imageData = data;
        _hasError = data == null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = widget.placeholder ?? Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_hasError || _imageData == null) {
      child = widget.errorWidget ?? Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image, color: Colors.grey.shade400),
      );
    } else {
      child = Image.memory(
        _imageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true, // Prevents flickering during updates
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: child,
      );
    }

    return child;
  }
}

/// Data preloader for fetching common data at app startup
class DataPreloader {
  static final DataPreloader _instance = DataPreloader._internal();
  factory DataPreloader() => _instance;
  DataPreloader._internal();

  bool _isPreloading = false;
  bool _isPreloaded = false;

  /// Preload all common data
  Future<void> preloadAllData() async {
    if (_isPreloading || _isPreloaded) return;
    _isPreloading = true;

    try {
      await Future.wait([
        _preloadCommunityPosts(),
        _preloadFeedPosts(),
        _preloadCampaigns(),
        _preloadEvents(),
      ]);
      
      _isPreloaded = true;
      secureLog('DataPreloader: All data preloaded');
    } catch (e) {
      secureLog('DataPreloader error: $e');
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> _preloadCommunityPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      CacheService().cacheData('community_posts', posts);

      // Preload images from posts
      final imageUrls = <String>[];
      for (final post in posts) {
        if (post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty) {
          imageUrls.add(post['imageUrl']);
        }
        if (post['userAvatar'] != null && post['userAvatar'].toString().isNotEmpty) {
          imageUrls.add(post['userAvatar']);
        }
      }
      
      await CacheService().preloadNetworkImages(imageUrls);
      secureLog('Preloaded ${posts.length} community posts');
    } catch (e) {
      secureLog('Error preloading community posts: $e');
    }
  }

  Future<void> _preloadFeedPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      CacheService().cacheData('feed_posts', posts);

      // Preload images and videos
      final imageUrls = <String>[];
      for (final post in posts) {
        if (post['mediaUrl'] != null && post['mediaUrl'].toString().isNotEmpty) {
          final mediaType = post['mediaType'] ?? 'image';
          if (mediaType == 'image') {
            imageUrls.add(post['mediaUrl']);
          }
        }
        if (post['userAvatar'] != null && post['userAvatar'].toString().isNotEmpty) {
          imageUrls.add(post['userAvatar']);
        }
      }
      
      await CacheService().preloadNetworkImages(imageUrls);
      secureLog('Preloaded ${posts.length} feed posts');
    } catch (e) {
      secureLog('Error preloading feed posts: $e');
    }
  }

  Future<void> _preloadCampaigns() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('status', isEqualTo: 'active')
          .limit(10)
          .get();

      final campaigns = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      CacheService().cacheData('campaigns', campaigns);

      // Preload campaign images
      final imageUrls = <String>[];
      for (final campaign in campaigns) {
        if (campaign['imageUrl'] != null && campaign['imageUrl'].toString().isNotEmpty) {
          imageUrls.add(campaign['imageUrl']);
        }
      }
      
      await CacheService().preloadNetworkImages(imageUrls);
      secureLog('Preloaded ${campaigns.length} campaigns');
    } catch (e) {
      secureLog('Error preloading campaigns: $e');
    }
  }

  Future<void> _preloadEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .limit(10)
          .get();

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      CacheService().cacheData('events', events);
      secureLog('Preloaded ${events.length} events');
    } catch (e) {
      secureLog('Error preloading events: $e');
    }
  }

  /// Refresh cached data in background
  Future<void> refreshCache() async {
    _isPreloaded = false;
    await preloadAllData();
  }
}
