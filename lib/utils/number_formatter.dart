import 'package:intl/intl.dart';

String thousandSeparator(num value, [int decimals = 2, int minDecimals = 0]) {
  final formatter = NumberFormat('#,##0.${'0' * minDecimals}${'#' * (decimals - minDecimals)}', 'en_US');
  return formatter.format(value);
}
