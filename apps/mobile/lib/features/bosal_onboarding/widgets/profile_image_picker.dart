import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 보살 프로필 사진 업로더.
///
/// - `image_picker` 로 갤러리에서 선택 (또는 카메라)
/// - Supabase Storage `bosal-images` 버킷에 `<bosal_id>/profile.<ext>` 로 upsert
/// - public URL 반환 → 부모가 `bosal_images` 테이블에 insert/update
///
/// MVP 단순화: 단일 이미지 (kind='profile'), 갤러리만, 압축은 image_picker 자체
/// imageQuality 80 + maxWidth 1024로 처리. 별도 image 패키지 없이.
class ProfileImagePicker extends StatefulWidget {
  final String bosalId;
  final String? currentUrl;
  final void Function(String publicUrl) onUploaded;

  const ProfileImagePicker({
    super.key,
    required this.bosalId,
    required this.currentUrl,
    required this.onUploaded,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  bool _uploading = false;
  String? _error;
  String? _previewUrl;

  Future<void> _pickAndUpload(ImageSource source) async {
    setState(() {
      _error = null;
      _uploading = true;
    });
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (file == null) {
        setState(() => _uploading = false);
        return;
      }

      final ext = file.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext)
          ? (ext == 'jpeg' ? 'jpg' : ext)
          : 'jpg';
      final path = '${widget.bosalId}/profile.$safeExt';

      final bytes = await File(file.path).readAsBytes();
      await supabase.storage.from('bosal-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$safeExt',
            ),
          );

      final url = supabase.storage.from('bosal-images').getPublicUrl(path);
      // 캐시 갱신 위해 query string 추가
      final cacheBusted = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      // bosal_images 테이블에 upsert
      // 단일 'profile' 이미지를 보장하기 위해 기존 profile 행 삭제 후 insert
      await supabase
          .from('bosal_images')
          .delete()
          .eq('bosal_id', widget.bosalId)
          .eq('kind', 'profile');
      await supabase.from('bosal_images').insert({
        'bosal_id': widget.bosalId,
        'url': cacheBusted,
        'kind': 'profile',
        'sort_order': 0,
      });

      if (!mounted) return;
      setState(() {
        _previewUrl = cacheBusted;
        _uploading = false;
      });
      widget.onUploaded(cacheBusted);
    } on StorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '업로드 실패: ${e.message}';
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '업로드 실패. 잠시 후 다시 시도해주세요.';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shownUrl = _previewUrl ?? widget.currentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                image: shownUrl != null
                    ? DecorationImage(
                        image: NetworkImage(shownUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: shownUrl == null
                  ? const Icon(Icons.person_rounded,
                      size: 48, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('프로필 사진',
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '회원에게 가장 먼저 보이는 이미지입니다.',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _ActionChip(
                        icon: Icons.photo_library_outlined,
                        label: '갤러리',
                        onTap: _uploading
                            ? null
                            : () => _pickAndUpload(ImageSource.gallery),
                      ),
                      _ActionChip(
                        icon: Icons.photo_camera_outlined,
                        label: '카메라',
                        onTap: _uploading
                            ? null
                            : () => _pickAndUpload(ImageSource.camera),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_uploading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: AppTextStyles.small
                  .copyWith(color: AppColors.danger, fontSize: 13)),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: disabled ? AppColors.bg : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}
