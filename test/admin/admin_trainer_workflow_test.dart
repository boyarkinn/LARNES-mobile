import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_workflow.dart';

void main() {
  group('TrainerWorkflowDetail.fromJson', () {
    test('parses trainer meta and web/mobile snapshots', () {
      final detail = TrainerWorkflowDetail.fromJson({
        'status': 'success',
        'currentUserId': 'admin-1',
        'trainer': {
          'key': 'flashcard-digit-match',
          'title': 'Flashcards',
          'direction': 'mental',
        },
        'web': _snapshotJson('web', 'in_development'),
        'mobile': _snapshotJson('mobile', 'ready_for_release'),
      });

      expect(detail.trainer.key, 'flashcard-digit-match');
      expect(detail.trainer.title, 'Flashcards');
      expect(detail.currentUserId, 'admin-1');
      expect(detail.web.platform, TrainerWorkflowPlatform.web);
      expect(detail.mobile.platform, TrainerWorkflowPlatform.mobile);
      expect(detail.web.release.lifecycleStatus, TrainerReleaseLifecycleStatus.inDevelopment);
      expect(
        detail.mobile.release.lifecycleStatus,
        TrainerReleaseLifecycleStatus.readyForRelease,
      );
      expect(detail.web.feed, hasLength(1));
      expect(detail.web.feed.first.authorName, 'Alex');
      expect(detail.web.feed.first.attachments, hasLength(1));
      expect(detail.web.reviewers.first.signoffStatus, TrainerSignoffStatus.needsFixes);
    });
  });
}

Map<String, dynamic> _snapshotJson(String platform, String lifecycleStatus) {
  return {
    'trainerKey': 'flashcard-digit-match',
    'platform': platform,
    'inProgressCommentCount': 1,
    'isReadyForRelease': false,
    'release': {
      'trainerKey': 'flashcard-digit-match',
      'lifecycleStatus': lifecycleStatus,
      'updatedAt': '2026-07-10T12:00:00.000Z',
    },
    'reviewers': [
      {
        'userId': 'admin-1',
        'displayName': 'Alex Admin',
        'signoffStatus': 'needs_fixes',
      },
    ],
    'feed': [
      {
        'id': 'comment-1',
        'kind': 'comment',
        'body': 'Fix spacing',
        'status': 'in_progress',
        'createdAt': '2026-07-10T11:00:00.000Z',
        'resolvedAt': null,
        'author': {'id': 'admin-2', 'displayName': 'Alex'},
        'attachments': [
          {
            'id': 'att-1',
            'mime': 'image/png',
            'dataUrl': 'data:image/png;base64,AA==',
            'width': 100,
            'height': 50,
          },
        ],
      },
    ],
  };
}
