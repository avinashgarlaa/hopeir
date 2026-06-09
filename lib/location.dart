import 'dart:async';

void simulateDriverMovement() {
  const startLat = 31.532;
  const startLng = 74.3500;

  const endLat = 31.5497;
  const endLng = 74.3436;

  const steps = 100;

  double latStep = (endLat - startLat) / steps;
  double lngStep = (endLng - startLng) / steps;

  int currentStep = 0;

  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (currentStep > steps) {
      timer.cancel();
      print("🏁 Destination reached");
      return;
    }

    final lat = startLat + (latStep * currentStep);
    final lng = startLng + (lngStep * currentStep);

    print({
      "latitude": lat,
      "longitude": lng,
    });

    // sendDriverLocation(
    //   lat: lat,
    //   lng: lng,
    // );

    currentStep++;
  });
}
