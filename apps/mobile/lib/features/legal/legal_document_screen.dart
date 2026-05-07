import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 약관·개인정보처리방침 등 정적 마크다운 문서를 렌더하는 공용 화면.
///
/// 라우트:
/// - `/legal/terms` → assets/legal/terms.md
/// - `/legal/privacy` → assets/legal/privacy.md
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString(assetPath),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '문서를 불러오지 못했습니다',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.danger),
                  ),
                ),
              );
            }
            return Markdown(
              data: snapshot.data ?? '',
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                p: AppTextStyles.body.copyWith(height: 1.6),
                h1: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
                h2: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
                h3: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                blockquote: AppTextStyles.small.copyWith(
                  color: AppColors.textSub,
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.bg,
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                tableBody: AppTextStyles.small,
                tableHead: AppTextStyles.smallBold,
                code: AppTextStyles.small.copyWith(
                  backgroundColor: AppColors.bg,
                  fontFamily: 'monospace',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
