import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A small utility class that shows a customizable About dialog.
///
/// It's used like: `const AboutMe(...).showCustomAbout(context);`
class AboutMe {
  final String applicationName;
  final String developerName = "Elaz";
  final String companyName = "FEA";
  final String companyDomain = "https://support-elaz.netlify.app/";
  final String emailCompany = "f36823.support@gmail.com";
  final String phoneCompany = "+212662734323";
  final String version;
  final Widget? legalese = Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.asset("assets/elaz/logo.png", width: 24, height: 24),
        ),
        TextSpan(
          text: " © ${DateTime.now().year}. All rights reserved. | Elaz",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        ),
      ],
    ),
    textAlign: TextAlign.center,
  );
  final String description;
  final List<Widget>? additionalContent;
  final Widget? logo;
  final Color? backgroundColor;
  final Color? textColor;

  AboutMe({
    required this.applicationName,
    required this.version,
    required this.description,
    this.additionalContent,
    this.logo,
    this.backgroundColor,
    this.textColor,
  });

  /// Shows the dialog. Returns when dismissed.
  Future<void> showCustomAbout(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              backgroundColor ?? Theme.of(context).dialogTheme.backgroundColor,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logo != null) ...[logo!, const SizedBox(height: 24)],
                  Text(
                    applicationName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Text(
                  //   "${AppLocalizations.of(context)!.translate('developer')}: $developerName",
                  //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  //     fontSize: 16.0,
                  //     color: textColor,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  // const SizedBox(height: 16),
                  // Text(
                  //   "${AppLocalizations.of(context)!.translate('company')}: $companyName\n${AppLocalizations.of(context)!.translate('site')}: $companyDomain\n${AppLocalizations.of(context)!.translate('email')}: $emailCompany\n${AppLocalizations.of(context)!.translate('phone')}: $phoneCompany",
                  //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  //     fontSize: 14.0,
                  //     color: textColor,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    'النسخة: $version',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),

                  if (legalese != null) ...[
                    const SizedBox(height: 8),
                    DefaultTextStyle(
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall!.copyWith(color: textColor),
                      child: legalese!,
                    ),
                  ],
                  if (additionalContent != null) ...[
                    const SizedBox(height: 12),
                    ...additionalContent!,
                  ],
                  SizedBox(height: 16),
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () => Navigator.of(context).pop(),
                  //     child: Text(
                  //       'إغلاق',
                  //       style: Theme.of(
                  //         context,
                  //       ).textTheme.bodyMedium?.copyWith(color: textColor),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

//Usage
Future<void> showAboutMe(
  BuildContext context,
  String logoPath,
  String title,
  String description,
) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  if (!context.mounted) return;
  await AboutMe(
    logo: Image.asset(logoPath, height: 100, width: 100),
    applicationName: title,
    version: version,
    description: description,
  ).showCustomAbout(context);
}
