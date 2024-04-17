import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final bool development = bool.parse(dotenv.env['DEVELOPMENT'] ?? 'true');

final String domainKey =
    development ? dotenv.env['D_DOMAIN_KEY']! : dotenv.env['P_DOMAIN_KEY']!;

final String appTitle = dotenv.env['APP_TITLE'] ?? 'Boodskap Digital Twin';
final String appFont = dotenv.env['APP_FONT'] ?? 'Acme';
final double appFontSize = double.parse(dotenv.env['APP_FONT_SIZE'] ?? '14');
final int appFontColor =
    int.parse(dotenv.env['AP_FONT_COLOR'] ?? '${Colors.black.value}');
