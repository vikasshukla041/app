import 'package:flutter/material.dart';

import '../../core/design_system/widgets/coming_soon.dart';
import '../../core/navigation/app_section.dart';
import '../../l10n/app_localizations.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navEducation,
      icon: AppSection.education.icon,
    );
  }
}
