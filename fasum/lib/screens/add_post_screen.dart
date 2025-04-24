import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;

// untuk mengkompres gambar
  Future <void> _compressAndEncodeImage()async{
    if (_image == null) return;
    final compressedImage = await FlutterImageCompress.compressWithFile(
      _image!.path,
      quality: 50,
    );
    if (compressedImage == null) return;
    setState(() {
      _base64Image = base64Encode(compressedImage);

    });
  }
  // untuk mengambil gambar
  Future <void> _pickImage(ImageSource source) async{
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _compressAndEncodeImage();
    }
  }
  // untuk mendapatkan location
  Future <void> _getLocation() async{
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      throw Exception(('Location Services are disbled'));
    }
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.deniedForever || 
          permission == LocationPermission.denied){
            throw Exception("Location Permissions are denied.");
          }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Filed to retrieve location: $e');
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }


// Untuk mengupload
  Future <void> _submitPost() async {
    if(_base64Image == null || _descriptionController.text.isEmpty)return ;
    setState(() => _isUploading = true);
    final now = DateTime.now().toIso8601String();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if(uid == null){
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found.'),),
      );
      return;
    }
    try{
      await _getLocation();
      // Ambil nama lengkap dari koleksi users
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final fullName = userDoc.data()?['fullName'] ?? 'Anonymous';
      await FirebaseFirestore.instance.collection('posts').add(
        {
          'image': _base64Image,
          'description': _descriptionController.text,
          'createdAt': now,
          'latitude': _latitude,
          'longitude': _longitude,
          'fullName': fullName,
          'userId': uid, // optional: jika ingin simpan UID juga
        }
      );
      if(!mounted) return;
      Navigator.pop(context);
    }catch(e){
      debugPrint('Upload failde: $e');
      if (!mounted) return;
      setState(()=> _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('failed to upload the psot.')),
      );
    }
  }

  void _showImageSourcedialog(){
    showDialog(
      context: context ,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Spurce'),
        actions: [
          TextButton(
            onPressed: (){
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            } ,
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: (){
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text("Gallery")),
        ],
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Post'),),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _image != null ?
            Image.file(
              _image!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
            : GestureDetector(
              onTap: _showImageSourcedialog,
              child: Container(
                height: 200,
                color: Colors.grey[500],
                child: const Center(
                  child: const Icon(Icons.add_a_photo, size: 50,),
                ),
              ),
            ),
            const SizedBox( height: 10,),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a brief description ......',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10,),
            _isUploading 
              ? CircularProgressIndicator()
              : ElevatedButton.icon(
                onPressed: _submitPost,
                icon: Icon(Icons.upload),
                label: Text('Post'),
                ),
          ],
        ),
      ),
    );
  }
} 