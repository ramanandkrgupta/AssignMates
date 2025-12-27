class OnboardingState {
  final String? collegeId;
  final String? city;
  final String? phoneNumber;
  final String? formattedAddress; // New field for readable address
  final double? latitude;
  final double? longitude;
  final bool notificationsEnabled;
  final bool cameraPermissionGranted;

  OnboardingState({
    this.collegeId,
    this.city,
    this.phoneNumber,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.notificationsEnabled = false,
    this.cameraPermissionGranted = false,
  });
  
  OnboardingState copyWith({
    String? collegeId,
    String? city,
    String? phoneNumber,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    bool? notificationsEnabled,
    bool? cameraPermissionGranted,
  }) {
    return OnboardingState(
      collegeId: collegeId ?? this.collegeId,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      cameraPermissionGranted: cameraPermissionGranted ?? this.cameraPermissionGranted,
    );
  }
}
