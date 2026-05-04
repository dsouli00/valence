
enum UserRole {
  coach,
  client,
}
enum ClientStatus {
  /// Client is on track with their goals
  onTrack,

  /// Client is slipping (missed one day)
  slipping,

  /// Client is at risk (missed 2+ days)
  atRisk,
}

enum SleepQuality {
  poor,
  fair,
  good,
  excellent,
}
