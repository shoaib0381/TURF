import 'package:turf/features/activity/domain/models/activity_session.dart';
import 'package:turf/features/profile/domain/models/profile.dart';

class FeedActivity {
  final ActivitySession session;
  final Profile profile;
  
  // Computed fields from session.metadata for social features
  int get likeCount => (session.metadata['like_count'] as num?)?.toInt() ?? 0;
  int get commentCount => (session.metadata['comment_count'] as num?)?.toInt() ?? 0;
  int get territoriesCaptured => (session.metadata['territories_captured'] as num?)?.toInt() ?? 0;

  FeedActivity({
    required this.session,
    required this.profile,
  });

  factory FeedActivity.fromJson(Map<String, dynamic> json) {
    // Expected structure: an activity_session row that includes a joined 'profiles' object
    final profileJson = json['profiles'] as Map<String, dynamic>? ?? {};
    
    // We clean up the json map before passing to ActivitySession to prevent issues, 
    // though ActivitySession.fromJson should ignore extra fields.
    return FeedActivity(
      session: ActivitySession.fromJson(json),
      profile: Profile.fromJson(profileJson),
    );
  }
}
