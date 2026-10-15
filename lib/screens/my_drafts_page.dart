import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/listing_draft_repository.dart';
import '../repositories/item_repository_firestore.dart';
import '../models/item.dart';
import '../services/firestore_image_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({
    super.key,
    required this.repository,
  });

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  int? _postingDraftId;
  Future<List<ListingDraftRow>> _loadDrafts() {
    return widget.repository.getAllDrafts();
  }

  Future<void> _deleteDraft(int id) async {
    try {
      await widget.repository.deleteDraft(id);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบร่างประกาศแล้ว'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถลบร่างประกาศได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<double?> _askPrice() async {
    return showDialog<double>(
      context: context,
      builder: (_) => const _PriceDialog(),
    );
  }

  Future<void> _postDraft(ListingDraftRow draft) async {
    if (_postingDraftId != null) return;
    final price = await _askPrice();
    if (price == null || !mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์สินค้า')),
      );
      return;
    }
    setState(() => _postingDraftId = draft.id);
    try {
      final imageUrl = await FirestoreImageService()
          .encodeListingImage(File(draft.imagePath));
      final item = Item(
        id: DateTime.now().microsecondsSinceEpoch,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );
      await ItemRepositoryFirestore().postItem(item);
      await widget.repository.deleteDraft(draft.id);
      if (!mounted) return;
      setState(() => _postingDraftId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โพสต์ขายสินค้าสำเร็จ และลบร่างแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _postingDraftId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โพสต์สินค้าไม่สำเร็จ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _loadDrafts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          final drafts = snapshot.data ?? [];

          if (drafts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ยังไม่มีร่างประกาศ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'สร้างร่างประกาศจากหน้า ลงประกาศขาย',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              draft.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ลบร่างประกาศ',
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteDraft(draft.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'หมวดหมู่: ${draft.category}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(draft.description),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _postingDraftId == null ? () => _postDraft(draft) : null,
                          icon: _postingDraftId == draft.id
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_postingDraftId == draft.id ? 'กำลังแปลงรูปและโพสต์...' : 'โพสต์ขายจริง'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'แก้ไขล่าสุด: ${draft.updatedAt}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog();

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_controller.text.trim());
    if (price == null || !price.isFinite || price <= 0) {
      setState(() => _error = 'กรอกราคาเป็นตัวเลขที่มากกว่า 0');
      return;
    }
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('กำหนดราคาสินค้า'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'ราคา (บาท)', errorText: _error),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('ยืนยันราคา'),
          ),
        ],
      );
}
