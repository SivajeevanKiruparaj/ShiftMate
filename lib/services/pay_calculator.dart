class PayCalculator {
  static double calculateHours({
    required int startHour,
    required int endHour,
    required int breakMinutes,
  }) {
    double hours =
        endHour - startHour - (breakMinutes / 60);

    return hours;
  }

  static double calculatePay({
    required double hours,
    required double rate,
  }) {
    return hours * rate;
  }
}