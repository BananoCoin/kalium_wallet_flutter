import 'dart:math';
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

class NumberUtil {
  final BigInt rawPerBan = BigInt.from(10).pow(29);
  static const int DEFAULT_DECIMAL_DIGITS = 2;

  int maxDecimalDigits; // Max digits after decimal

  NumberUtil({this.maxDecimalDigits = DEFAULT_DECIMAL_DIGITS});

  /// Convert raw to ban and return as BigDecimal
  ///
  /// @param raw 100000000000000000000000000000
  /// @return Decimal value 1.000000000000000000000000000000
  ///
  Decimal getRawAsUsableDecimal(String raw) {
    Decimal amount = Decimal.parse(raw.toString());
    Decimal result = amount / Decimal.parse(rawPerBan.toString());
    return result;
  }

  /// Truncate a Decimal to a specific amount of digits
  ///
  /// @param input 1.059
  /// @return double value 1.05
  ///
  double truncateDecimal(Decimal input, {int digits = DEFAULT_DECIMAL_DIGITS}) {
    return (input * Decimal.fromInt(pow(10, digits))).truncateToDouble() / pow(10, digits);
  }

  /// Return raw as a normal amount.
  ///
  /// @param raw 100000000000000000000000000000
  /// @returns 1
  ///
  String getRawAsUsableString(String raw) {
    NumberFormat nf = new NumberFormat.currency(locale:'en_US', decimalDigits: maxDecimalDigits, symbol:'');
    String asString = nf.format(truncateDecimal(getRawAsUsableDecimal(raw)));
    var split = asString.split(".");
    if (split.length > 1) {
      // Remove trailing 0s from this
      if (int.parse(split[1]) == 0) {
        asString = split[0];
      } else {
        String newStr = split[0] + ".";
        String digits = split[1];
        int endIndex = digits.length;
        for (int i = 1; i <= digits.length; i++) {
          if (int.parse(digits[digits.length - i]) == 0) {
            endIndex--;
          } else {
            break;
          }
        }
        digits = digits.substring(0, endIndex);
        newStr = split[0] + "." + digits;
        asString = newStr;
      }
    }
    return asString;
  }

  /// Return readable string amount as raw string
  /// @param amount 1.01
  /// @returns  101000000000000000000000000000
  ///
  String getAmountAsRaw(String amount) {
    Decimal asDecimal = Decimal.parse(amount);
    Decimal rawDecimal = Decimal.parse(rawPerBan.toString());
    return (asDecimal * rawDecimal).toString();
  }

  /// Sanitize a number as something that can actually
  /// be parsed. Expects "." to be decimal separator
  /// @param amount $1,512
  /// @returns 1.512
  String sanitizeNumber(String input) {
    String sanitized = "";
    for (int i=0; i< input.length; i++) {
      try {
        if (input[i] == ".") {
          sanitized = sanitized + input[i];
        } else {
          int.parse(input[i]);
          sanitized = sanitized + input[i];
        }
      } catch (e) { }
    }
    return sanitized;
  }
}