class OnboardingState {
  final String? collegeId;
  final String? city;
  final bool notificationsEnabled;
  final bool cameraPermissionGranted;

  OnboardingState({
    this.collegeId,
    this.city,
    this.notificationsEnabled = false,
    this.cameraPermissionGranted = false,
  });
  
  OnboardingState copyWith({
    String? collegeId,
    String? city,
    bool? notificationsEnabled,
    bool? cameraPermissionGranted,
  }) {
    return OnboardingState(
      collegeId: collegeId ?? this.collegeId,
      city: city ?? this.city,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      cameraPermissionGranted: cameraPermissionGranted ?? this.cameraPermissionGranted,
    );
  }
}
