import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/footer.dart';
import 'package:gaia/screens/blog/blog_articles.dart';

class BlogArticlePage extends StatelessWidget {
  const BlogArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final article = _resolveArticle(context);
    final contentWidth = size.width < 900 ? size.width * 0.9 : size.width * 0.7;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const GaiaNavBarAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(contentWidth, textTheme, article),
            _buildArticleBody(contentWidth, textTheme, article),
            _buildMoreReads(contentWidth, textTheme, article),
            const Footer(),
          ],
        ),
      ),
    );
  }

  BlogArticle _resolveArticle(BuildContext context) {
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final articleId = routeArguments is String ? routeArguments : '';

    for (final article in gaiaBlogArticles) {
      if (article.id == articleId) {
        return article;
      }
    }
    return gaiaBlogArticles.first;
  }

  Widget _buildHero(
    double contentWidth,
    TextTheme textTheme,
    BlogArticle article,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gray.shade100, AppColors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  article.category,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                article.title,
                style: textTheme.displaySmall?.copyWith(
                  color: AppColors.gray.shade900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  _metaTag(textTheme, article.publishedOn),
                  _metaTag(textTheme, article.readTime),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleBody(
    double contentWidth,
    TextTheme textTheme,
    BlogArticle article,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.gray.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.excerpt,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.gray.shade800,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < article.sections.length; i++) ...[
                  Text(
                    article.sections[i].title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.gray.shade900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    article.sections[i].body,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray.shade800,
                      height: 1.7,
                    ),
                  ),
                  if (i != article.sections.length - 1)
                    const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.turquoise.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.turquoise.shade800),
                  ),
                  child: Text(
                    'Key takeaway: ${article.keyTakeaway}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray.shade900,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreReads(
    double contentWidth,
    TextTheme textTheme,
    BlogArticle currentArticle,
  ) {
    final related = gaiaBlogArticles
        .where((item) => item.id != currentArticle.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More From GAIA Blog',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.gray.shade900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: related
                    .map(
                      (article) => _RelatedCard(
                        width: contentWidth < 700
                            ? contentWidth
                            : (contentWidth - AppSpacing.md) / 2,
                        article: article,
                        textTheme: textTheme,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaTag(TextTheme textTheme, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray.shade200),
      ),
      child: Text(
        value,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.gray.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({
    required this.width,
    required this.article,
    required this.textTheme,
  });

  final double width;
  final BlogArticle article;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        Navigator.pushReplacementNamed(
          context,
          Routes.blogArticle,
          arguments: article.id,
        );
      },
      child: Ink(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.gray.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.category,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              article.title,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.gray.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              article.readTime,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.gray.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
