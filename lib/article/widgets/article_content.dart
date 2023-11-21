import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:daily/ads/ads.dart';
import 'package:daily/analytics/analytics.dart';
import 'package:daily/article/article.dart';
import 'package:daily/l10n/l10n.dart';
import 'package:daily/network_error/network_error.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ArticleContent extends StatelessWidget {
  const ArticleContent({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select((ArticleBloc bloc) => bloc.state.status);
    final content = context.select((ArticleBloc bloc) => bloc.state.content);
    final uri = context.select((ArticleBloc bloc) => bloc.state.uri);
    final hasMoreContent =
        context.select((ArticleBloc bloc) => bloc.state.hasMoreContent);
    final isFailure = context.select(
      (ArticleBloc bloc) => bloc.state.status == ArticleStatus.failure,
    );

    if (status == ArticleStatus.initial) {
      return const ArticleContentLoaderItem(
        key: Key('articleContent_empty_loaderItem'),
      );
    }

    return ArticleContentSeenListener(
      child: BlocListener<ArticleBloc, ArticleState>(
        listener: (context, state) {
          if (state.status == ArticleStatus.failure && state.content.isEmpty) {
            Navigator.of(context).push<void>(
              NetworkError.route(
                onRetry: () {
                  context.read<ArticleBloc>().add(const ArticleRequested());
                  Navigator.of(context).pop();
                },
              ),
            );
          } else if (state.status == ArticleStatus.shareFailure) {
            _handleShareFailure(context);
          }
        },
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            SelectionArea(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: content.length + 1,
                itemBuilder: (context, index) {
                  if (index == content.length) {
                    if (isFailure) {
                      return NetworkError(
                        onRetry: () {
                          context
                              .read<ArticleBloc>()
                              .add(const ArticleRequested());
                        },
                      );
                    }
                    return hasMoreContent
                        ? Padding(
                            padding: EdgeInsets.only(
                              top: content.isEmpty ? AppSpacing.xxxlg : 0,
                            ),
                            child: ArticleContentLoaderItem(
                              key: const Key(
                                'articleContent_moreContent_loaderItem',
                              ),
                              onPresented: () {
                                if (status != ArticleStatus.loading) {
                                  context
                                      .read<ArticleBloc>()
                                      .add(const ArticleRequested());
                                }
                              },
                            ),
                          )
                        : const ArticleTrailingContent();
                  }

                  final block = content[index];
                  return VisibilityDetector(
                    key: ValueKey(block),
                    onVisibilityChanged: (visibility) {
                      if (!visibility.visibleBounds.isEmpty) {
                        context
                            .read<ArticleBloc>()
                            .add(ArticleContentSeen(contentIndex: index));
                      }
                    },
                    child: ArticleContentItem(
                      block: block,
                      onSharePressed: uri != null && uri.toString().isNotEmpty
                          ? () => context.read<ArticleBloc>().add(
                                ShareRequested(uri: uri),
                              )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const StickyAd(),
          ],
        ),
      ),
    );
  }

  void _handleShareFailure(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('articleContent_shareFailure_snackBar'),
          content: Text(
            context.l10n.shareFailure,
          ),
        ),
      );
  }
}

class ArticleContentSeenListener extends StatelessWidget {
  const ArticleContentSeenListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArticleBloc, ArticleState>(
      listener: (context, state) => context.read<AnalyticsBloc>().add(
            TrackAnalyticsEvent(
              ArticleMilestoneEvent(
                milestonePercentage: state.contentMilestone,
                articleTitle: state.title!,
              ),
            ),
          ),
      listenWhen: (previous, current) =>
          previous.contentMilestone != current.contentMilestone,
      child: child,
    );
  }
}
