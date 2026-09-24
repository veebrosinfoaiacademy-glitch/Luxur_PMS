import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pms_vbis/features/telecaller/presentation/import_leads_view.dart';
import 'package:pms_vbis/features/telecaller/state/telecaller_view_model.dart';
import '../support/fake_telecaller_lead_repository.dart';

/// The import flow is: choose a file → REVIEW what will be imported →
/// confirm → summary. The whole point of the review step is that nothing is
/// written until the user confirms, so these drive the real view and view
/// model against an in-memory repository and count what would have been
/// saved.
void main() {
  Future<void> pumpView(
    WidgetTester tester, {
    required FakeTelecallerLeadRepository repo,
    required String csv,
    String fileName = 'leads.csv',
    Size size = const Size(1280, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportLeadsView(
            viewModel: TelecallerViewModel(repo),
            pickFile: () async => ImportFileSelection(
              name: fileName,
              bytes: Uint8List.fromList(utf8.encode(csv)),
              isCsv: true,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  const header = 'Name,Phone,Expected Arrival Date,Address,Concern\r\n';

  testWidgets('choosing a file shows a review and saves nothing until Confirm', (tester) async {
    final repo = FakeTelecallerLeadRepository(existingPhones: {'9876543002'});
    await pumpView(
      tester,
      repo: repo,
      csv: '$header'
          'Priya Menon,9876543001,25/09/2030,Kochi,Laser\r\n'
          'Arjun Nair,9876543002,26/09/2030,Ernakulam,Acne\r\n'
          'Bad Date,9876543003,not a date,,\r\n',
    );

    await tapKey(tester, 'import_pick_file_button');

    // Review is showing — and nothing has been written.
    expect(find.byKey(const Key('import_preview')), findsOneWidget);
    expect(find.byKey(const Key('import_summary')), findsNothing);
    expect(repo.createCalls, 0);

    // The lead that will be imported, with its date spelled out unambiguously.
    expect(find.text('Priya Menon'), findsOneWidget);
    expect(find.text('25 Sep 2030'), findsOneWidget);
    // The one already in the database and the one with a bad date are shown
    // as skipped, with reasons.
    expect(find.textContaining('Arjun Nair'), findsOneWidget);
    expect(find.textContaining('Already exists'), findsOneWidget);
    expect(find.textContaining('Invalid expected arrival date'), findsOneWidget);
    expect(find.text('Confirm & Import 1 Lead'), findsOneWidget);

    await tapKey(tester, 'import_confirm_button');

    // Only now is it saved — with the expected arrival date carried through.
    expect(repo.createCalls, 1);
    expect(repo.createdPhones, ['9876543001']);
    expect(repo.createdExpectedArrivals, [DateTime(2030, 9, 25)]);
    expect(find.byKey(const Key('import_summary')), findsOneWidget);
    expect(find.byKey(const Key('import_preview')), findsNothing);
  });

  testWidgets('Cancel discards the review without saving anything', (tester) async {
    final repo = FakeTelecallerLeadRepository();
    await pumpView(
      tester,
      repo: repo,
      csv: '${header}Priya Menon,9876543001,25/09/2030,Kochi,Laser\r\n',
    );

    await tapKey(tester, 'import_pick_file_button');
    expect(find.byKey(const Key('import_preview')), findsOneWidget);

    await tapKey(tester, 'import_cancel_button');

    expect(repo.createCalls, 0);
    expect(find.byKey(const Key('import_preview')), findsNothing);
    expect(find.byKey(const Key('import_upload_card')), findsOneWidget);
  });

  testWidgets('with nothing valid to import, Confirm is disabled and says so', (tester) async {
    final repo = FakeTelecallerLeadRepository(existingPhones: {'9876543001'});
    await pumpView(
      tester,
      repo: repo,
      csv: '${header}Already There,9876543001,25/09/2030,,\r\n',
    );

    await tapKey(tester, 'import_pick_file_button');

    expect(find.byKey(const Key('import_preview_nothing_to_import')), findsOneWidget);
    final confirm = tester.widget<ElevatedButton>(find.byKey(const Key('import_confirm_button')));
    expect(confirm.onPressed, isNull);
    expect(repo.createCalls, 0);
  });

  testWidgets('warns when some leads have no expected arrival date', (tester) async {
    final repo = FakeTelecallerLeadRepository();
    await pumpView(
      tester,
      repo: repo,
      csv: '$header'
          'Has Date,9876543001,25/09/2030,,\r\n'
          'No Date,9876543002,,,\r\n',
    );

    await tapKey(tester, 'import_pick_file_button');

    expect(find.byKey(const Key('import_preview_no_date_note')), findsOneWidget);
    expect(find.textContaining('1 lead has no expected arrival date'), findsOneWidget);
    // Both are still importable — a missing date isn't an error.
    expect(find.text('Confirm & Import 2 Leads'), findsOneWidget);
  });

  testWidgets('no warning when every lead has an expected arrival date', (tester) async {
    final repo = FakeTelecallerLeadRepository();
    await pumpView(
      tester,
      repo: repo,
      csv: '${header}Has Date,9876543001,25/09/2030,,\r\n',
    );

    await tapKey(tester, 'import_pick_file_button');

    expect(find.byKey(const Key('import_preview_no_date_note')), findsNothing);
  });

  testWidgets('the review renders without overflow on a narrow window with many rows', (tester) async {
    // ~ the smallest usable content width (a 900px window minus the sidebar
    // and page padding), with enough rows that the table has to scroll
    // inside itself, plus long names/addresses and every skipped-row section.
    final rows = StringBuffer(header);
    for (var i = 0; i < 60; i++) {
      rows.write(
        'A Very Long Patient Name Number $i,98765${(43000 + i).toString()},25/09/2030,'
        'A long street address line for row $i in a big city,A long description of the concern\r\n',
      );
    }
    rows.write('Dup Person,9876500001,25/09/2030,,\r\n');
    rows.write('Broken Date Person,9876500002,soonish,,\r\n');
    final repo = FakeTelecallerLeadRepository(existingPhones: {'9876500001'});
    await pumpView(tester, repo: repo, csv: rows.toString(), size: const Size(700, 1800));

    await tapKey(tester, 'import_pick_file_button');

    expect(find.byKey(const Key('import_preview')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // 60 rows shown lazily inside a height-capped list, not all at once.
    expect(find.text('Confirm & Import 60 Leads'), findsOneWidget);
  });

  testWidgets('a file with the wrong columns shows the blocking error, not a review', (tester) async {
    final repo = FakeTelecallerLeadRepository();
    await pumpView(tester, repo: repo, csv: 'Something,Else\r\nx,y\r\n');

    await tapKey(tester, 'import_pick_file_button');

    expect(find.byKey(const Key('import_blocking_error')), findsOneWidget);
    expect(find.byKey(const Key('import_preview')), findsNothing);
    expect(repo.createCalls, 0);
  });
}
