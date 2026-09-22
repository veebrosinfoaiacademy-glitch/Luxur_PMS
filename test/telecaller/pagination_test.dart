import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/utils/pagination.dart';

void main() {
  group('paginate', () {
    test('returns all items on one page when fewer than page size', () {
      final result = paginate([1, 2, 3], requestedPage: 1, pageSize: 5);
      expect(result.items, [1, 2, 3]);
      expect(result.totalPages, 1);
      expect(result.currentPage, 1);
      expect(result.startIndex, 0);
    });

    test('splits into correct pages when more than page size', () {
      final items = List.generate(7, (i) => i); // [0..6]
      final page1 = paginate(items, requestedPage: 1, pageSize: 5);
      expect(page1.items, [0, 1, 2, 3, 4]);
      expect(page1.totalPages, 2);
      expect(page1.startIndex, 0);

      final page2 = paginate(items, requestedPage: 2, pageSize: 5);
      expect(page2.items, [5, 6]);
      expect(page2.startIndex, 5);
    });

    test(
      'exact multiple of page size does not produce a trailing empty page',
      () {
        final items = List.generate(10, (i) => i);
        final result = paginate(items, requestedPage: 1, pageSize: 5);
        expect(result.totalPages, 2);
      },
    );

    test(
      'clamps a requested page beyond the last page down to the last page',
      () {
        final items = List.generate(7, (i) => i);
        final result = paginate(items, requestedPage: 99, pageSize: 5);
        expect(result.currentPage, 2);
        expect(result.items, [5, 6]);
      },
    );

    test('clamps a requested page below 1 up to 1', () {
      final items = List.generate(7, (i) => i);
      final result = paginate(items, requestedPage: 0, pageSize: 5);
      expect(result.currentPage, 1);
    });

    test('an empty list yields one empty page, not zero pages', () {
      final result = paginate(<int>[], requestedPage: 1, pageSize: 5);
      expect(result.items, isEmpty);
      expect(result.totalPages, 1);
      expect(result.currentPage, 1);
    });
  });
}
