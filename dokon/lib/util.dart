import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

final _fmt = NumberFormat('#,###', 'uz');

String money(num v) => "${_fmt.format(v).replaceAll(',', ' ')} so'm";

void notify(BuildContext context, String msg, {String type = 'success'}) {
  Color c;
  IconData ic;
  switch (type) {
    case 'error':
      c = AppColors.danger;
      ic = Icons.error_outline;
      break;
    case 'info':
      c = AppColors.primary;
      ic = Icons.info_outline;
      break;
    case 'warning':
      c = AppColors.warning;
      ic = Icons.warning_amber_rounded;
      break;
    default:
      c = AppColors.secondary;
      ic = Icons.check_circle_outline;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [Icon(ic, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(msg))]),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      duration: const Duration(seconds: 3),
    ));
}
