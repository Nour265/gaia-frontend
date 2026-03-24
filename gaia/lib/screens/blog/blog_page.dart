import 'package:flutter/material.dart';
import 'package:gaia/app/routes.dart';
import 'package:gaia/screens/blog/blog_articles.dart';
import 'package:gaia/values/values.dart';
import 'package:gaia/widgets/navbar.dart';
import 'package:gaia/widgets/sections/footer.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    final contentWidth = size.width < 900 ? size.width * 0.9 : size.width * 0.7;
    final featured = gaiaBlogArticles.first;
    final latest = gaiaBlogArticles.skip(1).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const GaiaNavBarAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context, textTheme, featured, contentWidth, size.width),
            _buildLatestSection(context, textTheme, latest, contentWidth),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    TextTheme textTheme,
    BlogArticle featured,
    double contentWidth,
    double viewportWidth,
  ) {
    final isCompact = viewportWidth < 980;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.shade100.withValues(alpha: 0.4),
            AppColors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.gray.shade200),
                      ),
                      child: Text(
                        'GAIA BLOG',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.gray.shade700,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Health stories that lead to better decisions.',
                      style: textTheme.displaySmall?.copyWith(
                        color: AppColors.gray.shade900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Explore short, practical reads about symptom awareness, privacy, and when to seek care.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray.shade800,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _statChip(textTheme, '4 articles'),
                        _statChip(textTheme, 'Action-first guidance'),
                        _statChip(textTheme, 'Updated this week'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            Routes.blogArticle,
                            arguments: featured.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Read Featured Story',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) const SizedBox(width: AppSpacing.xl),
              Flexible(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(top: isCompact ? AppSpacing.lg : 0),
                  child: _FeaturedArticleCard(article: featured),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestSection(
    BuildContext context,
    TextTheme textTheme,
    List<BlogArticle> articles,
    double contentWidth,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest Articles',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.gray.shade900,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Click any article card to open the full story.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray.shade700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSingleColumn = constraints.maxWidth < 900;
                  final cardWidth = isSingleColumn
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.md) / 2;

                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: articles
                        .map(
                          (article) =>
                              _ArticleCard(width: cardWidth, article: article),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(TextTheme textTheme, String label) {
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
        label,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.gray.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  const _FeaturedArticleCard({required this.article});

  final BlogArticle article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () {
        Navigator.pushNamed(context, Routes.blogArticle, arguments: article.id);
      },
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.purple, AppColors.turquoise],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.shade100,
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(article.icon, color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Featured',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              article.title,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              article.excerpt,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.92),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatefulWidget {
  const _ArticleCard({required this.width, required this.article});

  final double width;
  final BlogArticle article;

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final article = widget.article;
    final borderColor = _hovered ? AppColors.purple : AppColors.gray.shade200;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.blogArticle,
            arguments: article.id,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: _hovered
              ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
              : Matrix4.identity(),
          width: widget.width,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gray.shade100,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      article.icon,
                      color: AppColors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      article.category,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                article.title,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.gray.shade900,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                article.excerpt,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray.shade700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${article.publishedOn} - ${article.readTime}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.gray.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
