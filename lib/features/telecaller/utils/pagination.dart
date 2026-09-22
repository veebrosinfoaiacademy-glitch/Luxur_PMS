/// Simple client-side pagination over an already-filtered list. Pulled out
/// of TelecallerDashboardView so the page-boundary math is independently
/// testable without rendering a widget tree.
class PageResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int startIndex; // 0-based index of items.first within the full list

  const PageResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.startIndex,
  });
}

PageResult<T> paginate<T>(
  List<T> items, {
  required int requestedPage,
  required int pageSize,
}) {
  final totalPages = items.isEmpty ? 1 : (items.length / pageSize).ceil();
  final page = requestedPage.clamp(1, totalPages);
  final start = (page - 1) * pageSize;
  final pageItems = items.skip(start).take(pageSize).toList();

  return PageResult(
    items: pageItems,
    currentPage: page,
    totalPages: totalPages,
    startIndex: start,
  );
}
