import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartsteps/models/child_profile.dart';
import 'package:smartsteps/screens/register_screen.dart';
import 'package:smartsteps/services/local_profile_storage.dart';
import 'package:smartsteps/theme/duo_theme.dart';
import 'package:smartsteps/view_models/registration_view_model.dart';

void main() {
  late Directory tempDirectory;
  late LocalProfileStorage profileStorage;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'smartsteps_registration_test_',
    );
    profileStorage = LocalProfileStorage(directoryOverride: tempDirectory);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('validates each step before moving forward', (tester) async {
    await _pumpRegistration(tester, profileStorage: profileStorage);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();

    expect(find.text('Hãy nhập tên của bé.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('registration-name-field')),
      findsOneWidget,
    );
  });

  testWidgets('back navigation preserves entered state', (tester) async {
    await _pumpRegistration(tester, profileStorage: profileStorage);

    await tester.enterText(
      find.byKey(const ValueKey('registration-name-field')),
      'Bé Minh',
    );
    await _tapPrimary(tester);
    await tester.tap(find.byKey(const ValueKey('registration-age-7')));
    await tester.tap(find.byKey(const ValueKey('registration-back-button')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('registration-name-field')),
    );
    expect(field.controller?.text, 'Bé Minh');
  });

  testWidgets('successful submit saves complete profile', (tester) async {
    var completed = false;
    final storage = _CapturingProfileStorage();
    await _pumpRegistration(
      tester,
      profileStorage: storage,
      onCompleted: (_) => completed = true,
    );

    await _completeWizard(tester);

    final profile = storage.savedProfile;
    expect(completed, isTrue);
    expect(profile?.childName, 'Bé An');
    expect(profile?.age, '6');
    expect(profile?.gender, 'Nam');
    expect(profile?.learningGoals, contains('Biết quan sát và đặt câu hỏi'));
    expect(profile?.avatarStoragePath, 'avatars/cat.webp');
    expect(profile?.acceptedTerms, isTrue);
  });

  test('legacy profile JSON remains compatible without avatarStoragePath', () {
    final profile = ChildProfile.fromJson({
      'childName': 'Bé An',
      'age': '6',
      'gender': 'Nam',
      'learningGoals': ['Biết quan sát'],
      'acceptedTerms': true,
      'completedAt': '2026-06-15T00:00:00.000',
    });

    expect(profile.avatarStoragePath, isNull);
    expect(profile.childName, 'Bé An');
  });

  test('age validation only accepts children from 4 to 10', () {
    final tooYoung =
        RegistrationViewModel(
            profileStorage: _CapturingProfileStorage(),
            isSurveyOnly: true,
          )
          ..updateName('Bé An')
          ..next()
          ..updateAge('3');
    expect(tooYoung.next(), isFalse);
    expect(
      tooYoung.validationMessage,
      'SmartSteps hiện phù hợp với trẻ từ 4 đến 10 tuổi.',
    );

    final tooOld =
        RegistrationViewModel(
            profileStorage: _CapturingProfileStorage(),
            isSurveyOnly: true,
          )
          ..updateName('Bé An')
          ..next()
          ..updateAge('11');
    expect(tooOld.next(), isFalse);
  });

  testWidgets('submit failure keeps wizard open and shows retry message', (
    tester,
  ) async {
    await _pumpRegistration(tester, profileStorage: _FailingProfileStorage());

    await _completeWizard(tester);

    expect(find.byKey(const ValueKey('registration-wizard')), findsOneWidget);
    expect(find.text('Chưa lưu được hồ sơ. Vui lòng thử lại.'), findsOneWidget);
  });

  for (final size in [const Size(390, 844), const Size(800, 1100)]) {
    testWidgets('renders without overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpRegistration(tester, profileStorage: profileStorage);
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byKey(const ValueKey('registration-name-field')),
        'Bé An',
      );
      await _tapPrimary(tester);
      expect(
        find.byKey(const ValueKey('registration-age-grid')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpRegistration(
  WidgetTester tester, {
  required LocalProfileStorage profileStorage,
  void Function(BuildContext context)? onCompleted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DuoTheme.light,
      home: RegisterScreen(
        profileStorage: profileStorage,
        viewModel: RegistrationViewModel(
          profileStorage: profileStorage,
          isSurveyOnly: true,
        ),
        onRegistrationCompleted: onCompleted ?? (_) {},
      ),
    ),
  );
  await tester.pump();
}

Future<void> _completeWizard(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('registration-name-field')),
    'Bé An',
  );
  await _tapPrimary(tester);
  await tester.tap(find.byKey(const ValueKey('registration-age-6')));
  await _tapPrimary(tester);
  await tester.tap(find.byKey(const ValueKey('registration-gender-Nam')));
  await _tapPrimary(tester);
  await tester.tap(
    find.byKey(
      const ValueKey('registration-goal-Biết quan sát và đặt câu hỏi'),
    ),
  );
  await _tapPrimary(tester);
  await tester.tap(
    find.byKey(const ValueKey('registration-avatar-avatars/cat.webp')),
  );
  await _tapPrimary(tester);
  final termsToggle = find.byKey(const ValueKey('registration-terms-toggle'));
  await tester.ensureVisible(termsToggle);
  await tester.pump();
  await tester.tap(termsToggle);
  await tester.tap(find.text('Hoàn tất'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapPrimary(WidgetTester tester) async {
  await tester.tap(find.text('Tiếp tục'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

class _FailingProfileStorage extends LocalProfileStorage {
  @override
  Future<void> saveProfile(ChildProfile profile) {
    throw const FileSystemException('Simulated write failure');
  }
}

class _CapturingProfileStorage extends LocalProfileStorage {
  ChildProfile? savedProfile;

  @override
  Future<void> saveProfile(ChildProfile profile) async {
    savedProfile = profile;
  }
}
