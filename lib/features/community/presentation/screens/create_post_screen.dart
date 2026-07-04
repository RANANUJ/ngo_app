import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../controllers/community_controller.dart';
import '../../domain/models/community.dart';

class CreatePostScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? userPhoto;
  final String userType;
  final String? communityId;
  final String? communityName;

  const CreatePostScreen({
    Key? key,
    this.userId,
    this.userName,
    this.userPhoto,
    required this.userType,
    this.communityId,
    this.communityName,
  }) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const Color primary = Color(0xFF0099B8);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  File? _selectedVideo;
  bool _isLoading = false;
  bool _isUploadingMedia = false;
  String? _selectedCommunityId;
  String? _selectedCommunityName;
  String? _location;
  double? _latitude;
  double? _longitude;
  List<Map<String, dynamic>> _userCommunities = [];
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.communityId != null) {
      _selectedCommunityId = widget.communityId;
      _selectedCommunityName = widget.communityName;
    }
    _loadUserCommunities();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCommunities() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final allDocs = await FirebaseFirestore.instance
          .collectionGroup('members')
          .get();
      final memberDocs = allDocs.docs.where((doc) => doc.id == userId).toList();

      List<Map<String, dynamic>> communities = [];
      for (var doc in memberDocs) {
        final communityRef = doc.reference.parent.parent;
        if (communityRef != null) {
          final communityDoc = await communityRef.get();
          if (communityDoc.exists) {
            final data = communityDoc.data() as Map<String, dynamic>;
            communities.add({
              'id': communityDoc.id,
              'name': data['name'] ?? 'Community',
              'imageUrl': data['imageUrl'],
            });
          }
        }
      }

      setState(() => _userCommunities = communities);
    } catch (e) {
      print('Error loading communities: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedVideo = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      if (fileSize > 100 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video must be less than 100MB')),
          );
        }
        return;
      }

      setState(() {
        _selectedVideo = file;
        _selectedImage = null;
      });
    }
  }

  Future<void> _pickLocation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: primary),
      ),
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Navigator.pop(context);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationStr = [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _location = locationStr;
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child(fileName);

      final uploadTask = ref.putFile(file);
      
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> _uploadVideo(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_videos')
          .child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && 
        _selectedImage == null && 
        _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content, image or video')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      String? imageUrl;
      String? videoUrl;

      if (_selectedImage != null) {
        setState(() => _isUploadingMedia = true);
        imageUrl = await _uploadImage(_selectedImage!);
        setState(() => _isUploadingMedia = false);
      }

      if (_selectedVideo != null) {
        setState(() => _isUploadingMedia = true);
        videoUrl = await _uploadVideo(_selectedVideo!);
        setState(() => _isUploadingMedia = false);
      }

      final controller = context.read<CommunityController>();

      final success = await controller.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        communityId: _selectedCommunityId ?? '',
        communityName: _selectedCommunityName ?? '',
        authorId: userId,
        authorName: widget.userName ?? 'User',
        authorPhoto: widget.userPhoto ?? '',
        authorType: widget.userType,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        location: _location,
        latitude: _latitude,
        longitude: _longitude,
      );

      // Increment posts count on community document if community was selected
      if (success && _selectedCommunityId != null && _selectedCommunityId!.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('communities')
              .doc(_selectedCommunityId)
              .update({'postsCount': FieldValue.increment(1)});
        } catch (_) {}
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${controller.error ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingMedia = false;
        });
      }
    }
  }

  void _showCommunityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Community',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.public, color: Colors.grey.shade600),
              ),
              title: const Text('General'),
              subtitle: const Text('Post to everyone'),
              trailing: _selectedCommunityId == null
                  ? const Icon(Icons.check_circle, color: primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedCommunityId = null;
                  _selectedCommunityName = null;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            if (_userCommunities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Join a community to post there',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...List.generate(_userCommunities.length, (index) {
                final community = _userCommunities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primary.withValues(alpha: 0.2),
                    backgroundImage: community['imageUrl'] != null &&
                            community['imageUrl'].isNotEmpty
                        ? NetworkImage(community['imageUrl'])
                        : null,
                    child: community['imageUrl'] == null ||
                            community['imageUrl'].isEmpty
                        ? const Icon(Icons.group, color: primary)
                        : null,
                  ),
                  title: Text(community['name']),
                  trailing: _selectedCommunityId == community['id']
                      ? const Icon(Icons.check_circle, color: primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCommunityId = community['id'];
                      _selectedCommunityName = community['name'];
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primary.withValues(alpha: 0.2),
                      backgroundImage: widget.userPhoto != null &&
                              widget.userPhoto!.isNotEmpty
                          ? NetworkImage(widget.userPhoto!)
                          : null,
                      child: widget.userPhoto == null || widget.userPhoto!.isEmpty
                          ? const Icon(Icons.person, color: primary)
                          : null,
                    ),
                    title: Text(
                      widget.userName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: GestureDetector(
                      onTap: _showCommunityPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedCommunityId != null ? Icons.group : Icons.public,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCommunityName ?? 'General',
                            style: const TextStyle(color: primary, fontSize: 12),
                          ),
                          const Icon(Icons.arrow_drop_down, color: primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  
                  if (_location != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: primary, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _location!,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _location = null;
                              _latitude = null;
                              _longitude = null;
                            }),
                            child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _titleController,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Title of the post',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Add description...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),

                  if (_isUploadingMedia)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uploading ${_selectedVideo != null ? 'video' : 'image'}... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(primary),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                  if (_selectedImage != null)
                    Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 24,
                          right: 24,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (_selectedVideo != null)
                    Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(width: double.infinity, color: Colors.grey.shade900),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.videocam, color: Colors.white, size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Video selected',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<int>(
                                      future: _selectedVideo!.length(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final sizeMB = snapshot.data! / (1024 * 1024);
                                          return Text(
                                            '${sizeMB.toStringAsFixed(1)} MB',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 24,
                          right: 24,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedVideo = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _buildActionButton(Icons.image, 'Photo', _pickImage, _selectedImage != null),
                _buildActionButton(Icons.videocam, 'Video', _pickVideo, _selectedVideo != null),
                _buildActionButton(Icons.location_on, 'Location', _pickLocation, _location != null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, bool isActive) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? primary : Colors.grey.shade600, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? primary : Colors.grey.shade700,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
