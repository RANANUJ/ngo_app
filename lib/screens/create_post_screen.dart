import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedCommunityId;
  String? _selectedCommunityName;
  List<Map<String, dynamic>> _userCommunities = [];

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
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCommunities() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final memberDocs = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> communities = [];
      for (var doc in memberDocs.docs) {
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
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child(fileName);

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': userId,
        'userName': widget.userName ?? 'User',
        'userPhoto': widget.userPhoto,
        'userType': widget.userType,
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl,
        'communityId': _selectedCommunityId,
        'communityName': _selectedCommunityName,
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update community posts count if posting to a community
      if (_selectedCommunityId != null) {
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(_selectedCommunityId)
            .update({'postsCount': FieldValue.increment(1)});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // General (no community)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.public, color: Colors.grey.shade600),
              ),
              title: const Text('General'),
              subtitle: const Text('Post to everyone'),
              trailing: _selectedCommunityId == null
                  ? Icon(Icons.check_circle, color: primary)
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
                    backgroundColor: primary.withOpacity(0.2),
                    backgroundImage: community['imageUrl'] != null &&
                            community['imageUrl'].isNotEmpty
                        ? NetworkImage(community['imageUrl'])
                        : null,
                    child: community['imageUrl'] == null ||
                            community['imageUrl'].isEmpty
                        ? Icon(Icons.group, color: primary)
                        : null,
                  ),
                  title: Text(community['name']),
                  trailing: _selectedCommunityId == community['id']
                      ? Icon(Icons.check_circle, color: primary)
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info & Community Selector
            ListTile(
              leading: CircleAvatar(
                backgroundColor: primary.withOpacity(0.2),
                backgroundImage: widget.userPhoto != null &&
                        widget.userPhoto!.isNotEmpty
                    ? NetworkImage(widget.userPhoto!)
                    : null,
                child: widget.userPhoto == null || widget.userPhoto!.isEmpty
                    ? Icon(Icons.person, color: primary)
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
                      style: TextStyle(color: primary, fontSize: 12),
                    ),
                    Icon(Icons.arrow_drop_down, color: primary, size: 18),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 6,
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            // Selected Image Preview
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            _buildActionButton(
              Icons.image,
              'Photo',
              _pickImage,
            ),
            _buildActionButton(
              Icons.videocam,
              'Video',
              () {},
            ),
            _buildActionButton(
              Icons.location_on,
              'Location',
              () {},
            ),
            _buildActionButton(
              Icons.tag,
              'Tag',
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primary, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
