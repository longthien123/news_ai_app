part of 'news_cubit.dart';

abstract class NewsState extends Equatable {
  const NewsState();
  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsListLoaded extends NewsState {
  final List<News> newsList;
  const NewsListLoaded(this.newsList);
  @override
  List<Object?> get props => [newsList];
}

class NewsDetailLoaded extends NewsState {
  final News news;
  const NewsDetailLoaded(this.news);
  @override
  List<Object?> get props => [news];
}

class NewsAdded extends NewsState {
  final News news;
  const NewsAdded(this.news);
  @override
  List<Object?> get props => [news];
}

class NewsError extends NewsState {
  final String message;
  const NewsError(this.message);
  @override
  List<Object?> get props => [message];
}

// External news states
class ExternalNewsLoading extends NewsState {}

class ExternalNewsLoaded extends NewsState {
  final List<ExternalNewsModel> newsList;
  const ExternalNewsLoaded(this.newsList);
  @override
  List<Object?> get props => [newsList];
}

class ExternalNewsSelected extends NewsState {
  final ExternalNewsModel selected;
  const ExternalNewsSelected(this.selected);
  @override
  List<Object?> get props => [selected];
}
