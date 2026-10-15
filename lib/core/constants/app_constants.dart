/// Campus Signal — App Constants
///
/// Central location for non-design app-level constants.
abstract final class AppConstants {
  // ─── App Identity ─────────────────────────────────────────────────────────
  static const String appName = 'Finders Keepers';
  static const String appTagline = 'Find what\'s lost.\nReturn what\'s found.';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.campustech.finders_keepers';

  // ─── Campus / Map ─────────────────────────────────────────────────────────
  /// Default campus center (latitude, longitude) — update for your campus
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.5946;
  static const double defaultZoom = 15.0;

  // ─── Firestore Collections ────────────────────────────────────────────────
  /// Architecture stubs — not yet connected
  static const String kItemsCollection = 'items';
  static const String kUsersCollection = 'users';
  static const String kClaimsCollection = 'claims';

  // ─── Firebase Storage Paths ───────────────────────────────────────────────
  static const String kItemImagesPath = 'item_images';
  static const String kClaimEvidencePath = 'claim_evidence';

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int kPageSize = 20;

  // ─── UI Limits ────────────────────────────────────────────────────────────
  static const int kDescriptionMaxLength = 500;
  static const int kMaxPhotosPerItem = 5;
  static const int kMaxImagesPerClaim = 3;

  // ─── Animation ────────────────────────────────────────────────────────────
  static const String kRouteWelcome = '/';
  static const String kRouteHome = '/home';
  static const String kRouteExplore = '/explore';
  static const String kRouteActivity = '/activity';
  static const String kRouteProfile = '/profile';
  static const String kRouteItemDetail = '/items/:id';
  static const String kRouteReportItem = '/report';
  static const String kRouteClaim = '/items/:id/claim';
  static const String kRouteSignIn = '/auth/sign-in';
  static const String kRouteSignUp = '/auth/sign-up';
}
