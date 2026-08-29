/// THE post-authentication routing ladder — the single answer to "where does
/// this user go now".
///
/// This exists because the ladder was written out by hand in three places
/// (splash, signup, login) and login was missing two rungs: it checked
/// `needsCoachLink` but not `needsIntake` or `needsCoachIntake`. A client who
/// abandoned intake, or a coach who abandoned coach-intake, could log in and
/// land straight in the app — the client then running on `TargetMacros()`'s
/// generic 2000 kcal / 150 / 200 / 65 defaults with nothing on screen saying
/// anything was unset.
///
/// ORDER IS LOAD-BEARING and must match the `needs*` getters on AuthProvider:
/// a client with no coach cannot do intake (their plan belongs to a coach
/// relationship that doesn't exist yet), so the coach link is checked first.
///
/// Add a rung here, never at a call site.
library;

import 'package:flutter/widgets.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../client/client_persistant_tabs.dart';
import '../coach/coach_persistant_tabs.dart';
import 'client_intake_screen.dart';
import 'coach_intake_screen.dart';
import 'get_started.dart';
import 'link_coach_screen.dart';

Widget landingScreenFor(AuthProvider auth) {
  if (!auth.isAuthenticated) return const GettingStartedScreen();
  if (auth.needsCoachLink) return const LinkCoachScreen();
  if (auth.needsIntake) return const ClientIntakeScreen();
  if (auth.needsCoachIntake) return const CoachIntakeScreen();
  return auth.currentUser?.role == UserRole.coach
      ? const CoachPersistantTabs()
      : const ClientPersistantTabs();
}
