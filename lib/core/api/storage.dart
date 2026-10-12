/// Image upload.
///
/// Before this, `add_product_screen` put `pickedFile.path` into `image_url` —
/// a path like `/data/user/0/com.example/cache/image_picker_1234.jpg`. The
/// product looked fine on the phone that listed it and was a broken image for
/// every other customer, which is the worst shape a bug can take: invisible to
/// the person who caused it.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageBuckets {
  static const products = 'product-images';
  static const avatars = 'avatars';
}

class UploadException implements Exception {
  final String message;
  const UploadException(this.message);
  @override
  String toString() => message;
}

/// Put a local file in a bucket and return the public URL to store on the row.
///
/// The object key starts with the uploader's user id because the storage
/// policies are written against `(storage.foldername(name))[1] = auth.uid()`:
/// you may write inside your own folder and nowhere else. Changing this prefix
/// means changing those policies too.
Future<String> uploadImage(
  File file, {
  String bucket = StorageBuckets.products,
}) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) throw const UploadException('Sign in before uploading an image.');

  final ext = p.extension(file.path).toLowerCase();
  final safeExt = const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext) ? ext : '.jpg';
  final key = '$uid/${DateTime.now().millisecondsSinceEpoch}$safeExt';

  try {
    await client.storage.from(bucket).upload(
          key,
          file,
          fileOptions: FileOptions(
            contentType: _contentType(safeExt),
            // These are content-addressed by timestamp and never rewritten, so
            // they can be cached hard.
            cacheControl: '31536000',
            upsert: false,
          ),
        );
  } on StorageException catch (e) {
    throw UploadException(_explain(e));
  }

  return client.storage.from(bucket).getPublicUrl(key);
}

String _contentType(String ext) => switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };

/// Storage errors are terse and arrive in front of somebody mid-task. The two
/// worth naming are the ones a person can actually do something about.
String _explain(StorageException e) {
  final m = e.message.toLowerCase();
  if (m.contains('bucket') && m.contains('not found')) {
    return 'The image store is not set up yet. The product was not saved.';
  }
  if (m.contains('policy') || m.contains('unauthorized') || e.statusCode == '403') {
    return 'You do not have permission to upload. Try signing in again.';
  }
  return 'Upload failed: ${e.message}';
}
