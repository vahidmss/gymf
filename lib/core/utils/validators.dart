bool isValidIranianPhoneNumber(String phone) {
  // بررسی کنید که شماره 11 رقمی و با 09 شروع بشه
  if (phone.length != 11 || !phone.startsWith('09')) {
    return false;
  }
  // فقط عدد باشه
  return RegExp(r'^[0-9]+$').hasMatch(phone);
}
