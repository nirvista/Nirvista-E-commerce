import 'package:flutter/material.dart';

// ─── Teal Design System (aligned with Vendor Dashboard) ───────────────────────
Color primaryColor = const Color(0xFF0D9488);       // _kTeal
Color defBgColor   = const Color(0xFFCCFBF1);       // _kTealLight
Color backgroundColor = const Color(0xFF0A3631);    // _kSidebar
Color fontPrimary  = const Color(0xFF0F2622);       // _kText

Color accentColor      = const Color(0xFF0D9488);   // _kTeal
Color lightAccentColor = const Color(0xFFCCFBF1);   // _kTealLight
Color black20          = const Color(0xFFE2EAE8);   // _kBorder
Color black40          = const Color(0xFF3C3F3E);
Color dividerColor     = const Color(0xFFE2EAE8);   // _kBorder
Color cardColor        = Colors.white;              // _kCard
Color redColor         = const Color(0xFFEF4444);   // _kRed

Color lightRedColor  = const Color(0xFFFEE2E2);     // _kRedLight

Color greyFont       = const Color(0xFF6B8680);     // _kTextMuted
Color greenColor     = const Color(0xFF22C55E);     // _kGreen

Color indicatorColor = const Color(0xFFF4F7F6);     // _kBg
Color itemGreyColor  = const Color(0xFFE2EAE8);
Color orangeColor    = const Color(0xFFF59E0B);     // _kAmber
Color appBarColor    = const Color(0xFFCCFBF1);     // _kTealLight

Color redFontColor   = const Color(0xFFEF4444);
Color redBgColor     = const Color(0xFFFEE2E2);
Color yellowBgColor  = const Color(0xFFFEF3C7);     // _kAmberLight
Color unAvailableColor  = const Color(0xFFE2EAE8);
Color slotSelectedColor = const Color(0xFFCCFBF1);
Color darkGreyColor  = const Color(0xFF0F2622);
Color unRatedColor   = const Color(0xFFFEF3C7);
Color ratedColor     = const Color(0xFFF59E0B);

Color shadowColor    = Colors.black12;
Color greyIconColor  = const Color(0xFF6B8680);     // _kTextMuted

getFontColor(BuildContext context) {
  return getCurrentTheme(context).textTheme.titleMedium!.color;
}

getFontBlackColor(BuildContext context) {
  return getCurrentTheme(context).textTheme.titleLarge!.color;
}

getDividerColor(BuildContext context) {
  return getCurrentTheme(context).dividerColor;
}

getFontGreyColor(BuildContext context) {
  return getCurrentTheme(context).textTheme.titleSmall!.color;
}

getCardColor(BuildContext context) {
  return getCurrentTheme(context).cardColor;
}

getGreyCardColor(BuildContext context) {
  return getCurrentTheme(context).indicatorColor;
}

getScaffoldColor(BuildContext context){
  return getCurrentTheme(context).scaffoldBackgroundColor;
}

ThemeData getLightThemeData() {
  return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF4F7F6), // _kBg — same as vendor dashboard
      hintColor: const Color(0xFF6B8680),               // _kTextMuted
      dividerColor: const Color(0xFFE2EAE8),            // _kBorder
      textTheme: const TextTheme(
        titleMedium: TextStyle(color: Color(0xFF0F2622)), // _kText
        titleSmall:  TextStyle(color: Color(0xFF6B8680)), // _kTextMuted
        titleLarge:  TextStyle(color: Color(0xFF0F2622)), // _kText
      ),
      splashColor: const Color(0xFFCCFBF1),              // _kTealLight
      hoverColor:  const Color(0xFFCCFBF1),
      cardColor:   Colors.white,                         // _kCard
      unselectedWidgetColor: const Color(0xFF6B8680),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2EAE8)),
      focusColor: Colors.transparent,
      disabledColor: const Color(0xFF6B8680),
      canvasColor: const Color(0xFFF4F7F6),
      shadowColor: const Color.fromRGBO(13, 148, 136, 0.08), // soft teal shadow
      primaryColor: const Color(0xFF0D9488),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFF0D9488),
        secondary: const Color(0xFF0D9488),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      tabBarTheme: const TabBarThemeData(indicatorColor: Color(0xFF0D9488)));
}

ThemeData getDarkThemeData() {
  return ThemeData(
      scaffoldBackgroundColor: "#161E2D".toColor(),
      hintColor: "#A5A4AA".toColor(),
      dividerColor: "#F1F1F1".toColor(),


      splashColor: "#161E2D".toColor(),
      hoverColor: "#21F6F7FF".toColor(),
      // focusColor: "#525E7B".toColor(),
      focusColor: Colors.transparent,
      dividerTheme: DividerThemeData(color: "#DFDFDF".toColor()),
      unselectedWidgetColor: "#525E7B".toColor(),
      cardColor: "#2D354F".toColor(),

      canvasColor: "#525E7B".toColor(),


      disabledColor: "#FFFFFF".toColor(),
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.4699999988079071),
      textTheme: TextTheme(
        titleMedium: TextStyle(color: "#FFFFFF".toColor()),
        titleSmall: TextStyle(color: "#A6ADBE".toColor()),
        titleLarge: TextStyle(color: "#FFFFFF".toColor()),
        // caption: TextStyle(color: "#7C7C7C".toColor())
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(secondary: accentColor), dialogTheme: DialogThemeData(backgroundColor: "#283048".toColor()), tabBarTheme: TabBarThemeData(indicatorColor: "#F9F9F9".toColor()));
}

Color getAccentColor(BuildContext context) {
  return getCurrentTheme(context).colorScheme.secondary;
}

// getFontSkip(BuildContext context) {
//   return getCurrentTheme(context).textTheme.titleSmall!.color;
// }

getFontHint(BuildContext context) {
  return getCurrentTheme(context).hintColor;
}

ThemeData getCurrentTheme(BuildContext context) {
  return Theme.of(context);
}

extension ColorExtension on String {
  toColor() {
    var hexColor = replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
  }
}
