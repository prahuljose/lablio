import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ml.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ml'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lablio'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navBiomarkers.
  ///
  /// In en, this message translates to:
  /// **'Biomarkers'**
  String get navBiomarkers;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeRecentResults.
  ///
  /// In en, this message translates to:
  /// **'Recent Results'**
  String get homeRecentResults;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeLogResult.
  ///
  /// In en, this message translates to:
  /// **'Log Result'**
  String get homeLogResult;

  /// No description provided for @homeUploadReport.
  ///
  /// In en, this message translates to:
  /// **'Upload Report'**
  String get homeUploadReport;

  /// No description provided for @homeScanReport.
  ///
  /// In en, this message translates to:
  /// **'Scan Report'**
  String get homeScanReport;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units & format'**
  String get settingsUnits;

  /// No description provided for @settingsSIUnits.
  ///
  /// In en, this message translates to:
  /// **'SI units'**
  String get settingsSIUnits;

  /// No description provided for @settingsSIUnitsSub.
  ///
  /// In en, this message translates to:
  /// **'Show values in mmol/L, µmol/L, etc.'**
  String get settingsSIUnitsSub;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock'**
  String get settingsBiometricLock;

  /// No description provided for @settingsBiometricLockSub.
  ///
  /// In en, this message translates to:
  /// **'Require unlock when opening the app'**
  String get settingsBiometricLockSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTooltip;

  /// No description provided for @profileShareWithDoctor.
  ///
  /// In en, this message translates to:
  /// **'Share with doctor'**
  String get profileShareWithDoctor;

  /// No description provided for @profileExportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get profileExportData;

  /// No description provided for @profileAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Lablio'**
  String get profileAboutApp;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @addEntryEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get addEntryEnterValidNumber;

  /// No description provided for @addEntryEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get addEntryEnterValue;

  /// No description provided for @addEntryForYourProfile.
  ///
  /// In en, this message translates to:
  /// **' (for your profile if sex-specific)'**
  String get addEntryForYourProfile;

  /// No description provided for @addEntryNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get addEntryNotes;

  /// No description provided for @addEntryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any context about this result…'**
  String get addEntryNotesHint;

  /// No description provided for @addEntryReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get addEntryReplace;

  /// No description provided for @addEntryReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace existing result?'**
  String get addEntryReplaceTitle;

  /// No description provided for @addEntryResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get addEntryResult;

  /// No description provided for @addEntryTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get addEntryTags;

  /// No description provided for @addEntryTestDate.
  ///
  /// In en, this message translates to:
  /// **'Test date'**
  String get addEntryTestDate;

  /// No description provided for @addReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Add report'**
  String get addReportTitle;

  /// No description provided for @authAgeRequirement.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 to use Lablio.'**
  String get authAgeRequirement;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get authBackToSignIn;

  /// No description provided for @authBloodTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get authBloodTypeLabel;

  /// No description provided for @authCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authCheckInbox;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authCreateYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateYourAccount;

  /// No description provided for @authDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get authDobLabel;

  /// No description provided for @authDobRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get authDobRequired;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authEnterName;

  /// No description provided for @authForgotLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotLink;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authHaveAccount;

  /// No description provided for @authHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get authHeightLabel;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmail;

  /// No description provided for @authMin6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get authMin6Chars;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get authNoAccount;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a secure link to set a new password.'**
  String get authResetSubtitle;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// No description provided for @authSectionAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get authSectionAboutYou;

  /// No description provided for @authSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authSectionAccount;

  /// No description provided for @authSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Select date of birth'**
  String get authSelectDob;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get authSexLabel;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignInButton;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Lablio account'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUpButton;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your biomarkers and understand your health'**
  String get authSignupSubtitle;

  /// No description provided for @authWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get authWeightLabel;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @biomarkerDetailHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get biomarkerDetailHistory;

  /// No description provided for @biomarkerDetailLatestResult.
  ///
  /// In en, this message translates to:
  /// **'LATEST RESULT'**
  String get biomarkerDetailLatestResult;

  /// No description provided for @biomarkerDetailLogFirst.
  ///
  /// In en, this message translates to:
  /// **'Log your first result to see trends.'**
  String get biomarkerDetailLogFirst;

  /// No description provided for @biomarkerDetailNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get biomarkerDetailNoEntries;

  /// No description provided for @biomarkersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get biomarkersClear;

  /// No description provided for @biomarkersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start by logging your first lab result.'**
  String get biomarkersEmptySubtitle;

  /// No description provided for @biomarkersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No biomarkers yet'**
  String get biomarkersEmptyTitle;

  /// No description provided for @biomarkersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get biomarkersFilterAll;

  /// No description provided for @biomarkersFilterOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of Range'**
  String get biomarkersFilterOutOfRange;

  /// No description provided for @biomarkersNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get biomarkersNoMatches;

  /// No description provided for @biomarkersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search biomarkers'**
  String get biomarkersSearchHint;

  /// No description provided for @biomarkersSortName.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get biomarkersSortName;

  /// No description provided for @biomarkersSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get biomarkersSortRecent;

  /// No description provided for @biomarkersSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get biomarkersSortStatus;

  /// No description provided for @biomarkersSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get biomarkersSortTooltip;

  /// No description provided for @biomarkersStatusHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get biomarkersStatusHigh;

  /// No description provided for @biomarkersStatusLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get biomarkersStatusLow;

  /// No description provided for @biomarkersStatusNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get biomarkersStatusNormal;

  /// No description provided for @customBiomarkerCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get customBiomarkerCategory;

  /// No description provided for @customBiomarkerCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Custom'**
  String get customBiomarkerCategoryHint;

  /// No description provided for @customBiomarkerDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get customBiomarkerDescription;

  /// No description provided for @customBiomarkerEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get customBiomarkerEnterName;

  /// No description provided for @customBiomarkerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customBiomarkerName;

  /// No description provided for @customBiomarkerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Omega-3 Index'**
  String get customBiomarkerNameHint;

  /// No description provided for @customBiomarkerRefHigh.
  ///
  /// In en, this message translates to:
  /// **'Ref. High'**
  String get customBiomarkerRefHigh;

  /// No description provided for @customBiomarkerRefLow.
  ///
  /// In en, this message translates to:
  /// **'Ref. Low'**
  String get customBiomarkerRefLow;

  /// No description provided for @customBiomarkerShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name'**
  String get customBiomarkerShortName;

  /// No description provided for @customBiomarkerShortNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. O3I'**
  String get customBiomarkerShortNameHint;

  /// No description provided for @customBiomarkerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add custom biomarker'**
  String get customBiomarkerTitle;

  /// No description provided for @customBiomarkerUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get customBiomarkerUnit;

  /// No description provided for @customBiomarkerUnitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. %'**
  String get customBiomarkerUnitHint;

  /// No description provided for @formEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get formEmail;

  /// No description provided for @formName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get formName;

  /// No description provided for @formSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get formSexFemale;

  /// No description provided for @formSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get formSexMale;

  /// No description provided for @formSexOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get formSexOther;

  /// No description provided for @formSexShortFemale.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get formSexShortFemale;

  /// No description provided for @formSexShortMale.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get formSexShortMale;

  /// No description provided for @homeBodyMap.
  ///
  /// In en, this message translates to:
  /// **'Body Map'**
  String get homeBodyMap;

  /// No description provided for @homeComingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'SOON'**
  String get homeComingSoonBadge;

  /// No description provided for @homeHealthInsights.
  ///
  /// In en, this message translates to:
  /// **'Health Insights'**
  String get homeHealthInsights;

  /// No description provided for @homeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get homeNoResults;

  /// No description provided for @homeNoResultsSub.
  ///
  /// In en, this message translates to:
  /// **'Start by logging your first lab result.'**
  String get homeNoResultsSub;

  /// No description provided for @homeOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of Range'**
  String get homeOutOfRange;

  /// No description provided for @homeReportsStat.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get homeReportsStat;

  /// No description provided for @homeResultsStat.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get homeResultsStat;

  /// No description provided for @homeScanReportAction.
  ///
  /// In en, this message translates to:
  /// **'Scan Report'**
  String get homeScanReportAction;

  /// No description provided for @homeScanReportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Scanning is coming soon'**
  String get homeScanReportComingSoon;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Log lab results and keep every value in one place, organized and searchable.'**
  String get onboardingBody1;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Watch how each marker changes over time with clear, colorful charts.'**
  String get onboardingBody2;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Attach lab PDFs to reports so your full history is always at hand.'**
  String get onboardingBody3;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Track your biomarkers'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'See your trends'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Keep your reports'**
  String get onboardingTitle3;

  /// No description provided for @profileDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, all reports, biomarker results, and uploaded files. This cannot be undone.'**
  String get profileDeleteConfirmBody;

  /// No description provided for @profileDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get profileDeleteForever;

  /// No description provided for @profileDeleteTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get profileDeleteTypeToConfirm;

  /// No description provided for @profileExportDataSub.
  ///
  /// In en, this message translates to:
  /// **'Download all results as CSV'**
  String get profileExportDataSub;

  /// No description provided for @profileMedicalRecord.
  ///
  /// In en, this message translates to:
  /// **'Medical record'**
  String get profileMedicalRecord;

  /// No description provided for @profileMedicalRecordSub.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations, allergies, conditions'**
  String get profileMedicalRecordSub;

  /// No description provided for @profileNoResultsToExport.
  ///
  /// In en, this message translates to:
  /// **'No results to export yet.'**
  String get profileNoResultsToExport;

  /// No description provided for @profileNoResultsToSummarize.
  ///
  /// In en, this message translates to:
  /// **'No results to summarize yet.'**
  String get profileNoResultsToSummarize;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Theme, units, biometric lock, language'**
  String get profileSettingsSub;

  /// No description provided for @profileShareWithDoctorSub.
  ///
  /// In en, this message translates to:
  /// **'PDF summary of your results'**
  String get profileShareWithDoctorSub;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in anytime.'**
  String get profileSignOutConfirm;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Lablio?'**
  String get profileSignOutTitle;

  /// No description provided for @reportDetailAddResult.
  ///
  /// In en, this message translates to:
  /// **'Add Result'**
  String get reportDetailAddResult;

  /// No description provided for @reportDetailLogResult.
  ///
  /// In en, this message translates to:
  /// **'Log a result'**
  String get reportDetailLogResult;

  /// No description provided for @reportDetailNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results linked yet'**
  String get reportDetailNoResults;

  /// No description provided for @reportDetailPdfError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the PDF.'**
  String get reportDetailPdfError;

  /// No description provided for @reportDetailResults.
  ///
  /// In en, this message translates to:
  /// **'Biomarker Results'**
  String get reportDetailResults;

  /// No description provided for @reportDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportDetailTitle;

  /// No description provided for @reportDetailViewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get reportDetailViewPdf;

  /// No description provided for @reportStatusHigh.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get reportStatusHigh;

  /// No description provided for @reportStatusLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get reportStatusLow;

  /// No description provided for @reportStatusNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get reportStatusNormal;

  /// No description provided for @reportsAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Report'**
  String get reportsAddButton;

  /// No description provided for @reportsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete report'**
  String get reportsDeleteTitle;

  /// No description provided for @reportsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Upload your first lab report to keep everything in one place.'**
  String get reportsEmptyBody;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsPdfAttached.
  ///
  /// In en, this message translates to:
  /// **'PDF attached'**
  String get reportsPdfAttached;

  /// No description provided for @scanClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get scanClose;

  /// No description provided for @scanFindingBiomarkers.
  ///
  /// In en, this message translates to:
  /// **'Finding biomarkers…'**
  String get scanFindingBiomarkers;

  /// No description provided for @scanNoTextDetected.
  ///
  /// In en, this message translates to:
  /// **'No text detected. Try a clearer photo.'**
  String get scanNoTextDetected;

  /// No description provided for @scanNoValuesBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any biomarker values. Here\'s the raw text we read:'**
  String get scanNoValuesBody;

  /// No description provided for @scanNoValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No values found'**
  String get scanNoValuesTitle;

  /// No description provided for @scanReadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Reading document…'**
  String get scanReadingDocument;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a report'**
  String get scanTitle;

  /// No description provided for @settingsAddTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag…'**
  String get settingsAddTagHint;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSub.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsChangePasswordSub;

  /// No description provided for @settingsDefaultTags.
  ///
  /// In en, this message translates to:
  /// **'Default tags'**
  String get settingsDefaultTags;

  /// No description provided for @settingsDefaultTagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Appear as quick suggestions when logging a result.'**
  String get settingsDefaultTagsHelp;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsNoBiometrics.
  ///
  /// In en, this message translates to:
  /// **'No biometrics or device lock set up on this device.'**
  String get settingsNoBiometrics;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get settingsResetDefaults;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name} 👋'**
  String homeGreeting(String name);

  /// No description provided for @homeAllInRange.
  ///
  /// In en, this message translates to:
  /// **'All {count} markers in range 🎉'**
  String homeAllInRange(int count);

  /// No description provided for @homeOutOfRangeSummary.
  ///
  /// In en, this message translates to:
  /// **'{out} of {total} markers out of range'**
  String homeOutOfRangeSummary(int out, int total);

  /// No description provided for @homeImproving.
  ///
  /// In en, this message translates to:
  /// **'{count} improving'**
  String homeImproving(int count);

  /// No description provided for @homeWorsening.
  ///
  /// In en, this message translates to:
  /// **'{count} worsening'**
  String homeWorsening(int count);

  /// No description provided for @authResetSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to {email}'**
  String authResetSentTo(String email);

  /// No description provided for @authYearsSuffix.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String authYearsSuffix(int age);

  /// No description provided for @profileAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{age} yrs'**
  String profileAgeYears(int age);

  /// No description provided for @profileDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {error}'**
  String profileDeleteAccountError(String error);

  /// No description provided for @profileExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String profileExportFailed(String error);

  /// No description provided for @profilePdfGenerateError.
  ///
  /// In en, this message translates to:
  /// **'Could not generate PDF: {error}'**
  String profilePdfGenerateError(String error);

  /// No description provided for @biomarkerDetailError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String biomarkerDetailError(String error);

  /// No description provided for @biomarkerDetailReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {low} – {high} {unit}'**
  String biomarkerDetailReference(String low, String high, String unit);

  /// No description provided for @biomarkersError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String biomarkersError(String error);

  /// No description provided for @biomarkersLatest.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String biomarkersLatest(String value, String unit);

  /// No description provided for @addEntryReferenceRange.
  ///
  /// In en, this message translates to:
  /// **'Reference range: {low} – {high} {unit}'**
  String addEntryReferenceRange(String low, String high, String unit);

  /// No description provided for @addEntryReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'A {name} result from {date} already exists ({value}). Replace it?'**
  String addEntryReplaceBody(String name, String date, String value);

  /// No description provided for @addEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Log {name}'**
  String addEntryTitle(String name);

  /// No description provided for @reportDetailRefRange.
  ///
  /// In en, this message translates to:
  /// **'{low} – {high} {unit}'**
  String reportDetailRefRange(String low, String high, String unit);

  /// No description provided for @reportsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”? This can’t be undone.'**
  String reportsDeleteConfirm(String title);

  /// No description provided for @reportsError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String reportsError(String error);

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String scanFailed(String error);

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created! Check your email to confirm.'**
  String get authAccountCreated;

  /// No description provided for @addEntryDateOfTest.
  ///
  /// In en, this message translates to:
  /// **'Test date'**
  String get addEntryDateOfTest;

  /// No description provided for @addEntrySaveResult.
  ///
  /// In en, this message translates to:
  /// **'Save result'**
  String get addEntrySaveResult;

  /// No description provided for @addEntryTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add a tag…'**
  String get addEntryTagHint;

  /// No description provided for @biomarkerDetailTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get biomarkerDetailTrend;

  /// No description provided for @homePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get homePinned;

  /// No description provided for @exportPreparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing your PDF…'**
  String get exportPreparingPdf;

  /// No description provided for @settingsTagsSaved.
  ///
  /// In en, this message translates to:
  /// **'Default tags saved'**
  String get settingsTagsSaved;

  /// No description provided for @customBiomarkerSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String customBiomarkerSaveError(String error);

  /// No description provided for @addEntryReplaceError.
  ///
  /// In en, this message translates to:
  /// **'Could not replace result: {error}'**
  String addEntryReplaceError(String error);

  /// No description provided for @addEntrySaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save result: {error}'**
  String addEntrySaveError(String error);

  /// No description provided for @authChangeButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get authChangeButton;

  /// No description provided for @authCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get authCurrentPassword;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmPassword;

  /// No description provided for @authEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get authEnterCurrentPassword;

  /// No description provided for @authNewMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'New password must differ from the current one'**
  String get authNewMustDiffer;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDontMatch;

  /// No description provided for @authCurrentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get authCurrentPasswordWrong;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get authPasswordChanged;

  /// No description provided for @authChangePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Could not change password: {error}'**
  String authChangePasswordError(String error);

  /// No description provided for @medicalTabVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get medicalTabVaccinations;

  /// No description provided for @medicalTabAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get medicalTabAllergies;

  /// No description provided for @medicalTabConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get medicalTabConditions;

  /// No description provided for @medicalSingularVaccination.
  ///
  /// In en, this message translates to:
  /// **'vaccination'**
  String get medicalSingularVaccination;

  /// No description provided for @medicalSingularAllergy.
  ///
  /// In en, this message translates to:
  /// **'allergy'**
  String get medicalSingularAllergy;

  /// No description provided for @medicalSingularCondition.
  ///
  /// In en, this message translates to:
  /// **'condition'**
  String get medicalSingularCondition;

  /// No description provided for @medicalSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get medicalSeverity;

  /// No description provided for @medicalSeverityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get medicalSeverityMild;

  /// No description provided for @medicalSeverityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get medicalSeverityModerate;

  /// No description provided for @medicalSeveritySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get medicalSeveritySevere;

  /// No description provided for @medicalStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get medicalStatus;

  /// No description provided for @medicalStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get medicalStatusActive;

  /// No description provided for @medicalStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get medicalStatusResolved;

  /// No description provided for @medicalDateGiven.
  ///
  /// In en, this message translates to:
  /// **'Date given'**
  String get medicalDateGiven;

  /// No description provided for @medicalDiagnosedOn.
  ///
  /// In en, this message translates to:
  /// **'Diagnosed on'**
  String get medicalDiagnosedOn;

  /// No description provided for @medicalFirstNoticed.
  ///
  /// In en, this message translates to:
  /// **'First noticed'**
  String get medicalFirstNoticed;

  /// No description provided for @medicalSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date (optional)'**
  String get medicalSelectDate;

  /// No description provided for @medicalNameVaccine.
  ///
  /// In en, this message translates to:
  /// **'Vaccine (e.g. Tdap, Covishield)'**
  String get medicalNameVaccine;

  /// No description provided for @medicalNameAllergen.
  ///
  /// In en, this message translates to:
  /// **'Allergen (e.g. Penicillin, Peanuts)'**
  String get medicalNameAllergen;

  /// No description provided for @medicalNameCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition (e.g. Asthma, Hypertension)'**
  String get medicalNameCondition;

  /// No description provided for @biomarkerDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get biomarkerDetailDeleteTitle;

  /// No description provided for @biomarkerDetailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this result? This cannot be undone.'**
  String get biomarkerDetailDeleteBody;

  /// No description provided for @biomarkerDetailWhatHighMeans.
  ///
  /// In en, this message translates to:
  /// **'What \"High\" usually means'**
  String get biomarkerDetailWhatHighMeans;

  /// No description provided for @biomarkerDetailWhatLowMeans.
  ///
  /// In en, this message translates to:
  /// **'What \"Low\" usually means'**
  String get biomarkerDetailWhatLowMeans;

  /// No description provided for @biomarkerDetailInfoDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'General information only — not medical advice.'**
  String get biomarkerDetailInfoDisclaimer;

  /// No description provided for @biomarkerDetailWhatMayHelp.
  ///
  /// In en, this message translates to:
  /// **'What may help'**
  String get biomarkerDetailWhatMayHelp;

  /// No description provided for @biomarkerDetailGuidanceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'General lifestyle guidance only — not medical advice.'**
  String get biomarkerDetailGuidanceDisclaimer;

  /// No description provided for @biomarkerDetailNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get biomarkerDetailNoteSaved;

  /// No description provided for @biomarkerDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get biomarkerDetailNotes;

  /// No description provided for @biomarkerDetailPinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pin to home'**
  String get biomarkerDetailPinTooltip;

  /// No description provided for @addReportTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Report title'**
  String get addReportTitleLabel;

  /// No description provided for @addReportTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Annual Blood Work'**
  String get addReportTitleHint;

  /// No description provided for @addReportDate.
  ///
  /// In en, this message translates to:
  /// **'Report date'**
  String get addReportDate;

  /// No description provided for @addReportNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add any notes about this report...'**
  String get addReportNotesHint;

  /// No description provided for @addReportPickPdf.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a PDF lab report'**
  String get addReportPickPdf;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review results'**
  String get reviewTitle;

  /// No description provided for @reviewShowText.
  ///
  /// In en, this message translates to:
  /// **'Show scanned text'**
  String get reviewShowText;

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Biomarker'**
  String get browseTitle;

  /// No description provided for @browseSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search biomarkers...'**
  String get browseSearchHint;

  /// No description provided for @biomarkersNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No biomarkers found'**
  String get biomarkersNoneFound;

  /// No description provided for @bodyMapSystems.
  ///
  /// In en, this message translates to:
  /// **'Systems'**
  String get bodyMapSystems;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSaveChanges;

  /// No description provided for @exportSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select biomarkers'**
  String get exportSelectTitle;

  /// No description provided for @exportSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what goes into the PDF summary'**
  String get exportSelectSubtitle;

  /// No description provided for @exportGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get exportGeneratePdf;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You’re all set.'**
  String get authPasswordUpdated;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// No description provided for @commonCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String commonCouldNotSave(String error);

  /// No description provided for @medicalAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add {item}'**
  String medicalAddItem(String item);

  /// No description provided for @medicalNoneLogged.
  ///
  /// In en, this message translates to:
  /// **'No {item} logged yet.'**
  String medicalNoneLogged(String item);

  /// No description provided for @medicalSeverityValue.
  ///
  /// In en, this message translates to:
  /// **'Severity: {value}'**
  String medicalSeverityValue(String value);

  /// No description provided for @medicalStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String medicalStatusValue(String value);

  /// No description provided for @biomarkerDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String biomarkerDetailAbout(String name);

  /// No description provided for @reviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} result(s)'**
  String reviewSaved(int count);

  /// No description provided for @reviewSaveCount.
  ///
  /// In en, this message translates to:
  /// **'Save {count} result(s)'**
  String reviewSaveCount(int count);

  /// No description provided for @reviewTestDate.
  ///
  /// In en, this message translates to:
  /// **'Test date: {date}'**
  String reviewTestDate(String date);

  /// No description provided for @authUpdatePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Could not update password: {error}'**
  String authUpdatePasswordError(String error);

  /// No description provided for @commonSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get commonSelect;

  /// No description provided for @formHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get formHeight;

  /// No description provided for @formWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get formWeight;

  /// No description provided for @editProfileAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated'**
  String get editProfileAvatarUpdated;

  /// No description provided for @editProfileImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please pick one under 2 MB.'**
  String get editProfileImageTooLarge;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @resetNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetNewPasswordTitle;

  /// No description provided for @resetNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your Lablio account.'**
  String get resetNewPasswordSubtitle;

  /// No description provided for @resetUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get resetUpdateButton;

  /// No description provided for @resetVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying reset link…'**
  String get resetVerifying;

  /// No description provided for @editProfileAvatarError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload picture: {error}'**
  String editProfileAvatarError(String error);

  /// No description provided for @biomarkersRefShort.
  ///
  /// In en, this message translates to:
  /// **'Ref: {low} – {high} {unit}'**
  String biomarkersRefShort(String low, String high, String unit);

  /// No description provided for @exportSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get exportSelectAll;

  /// No description provided for @exportClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get exportClearAll;

  /// No description provided for @exportSummaryMedical.
  ///
  /// In en, this message translates to:
  /// **'medical record'**
  String get exportSummaryMedical;

  /// No description provided for @addReportEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get addReportEnterTitle;

  /// No description provided for @addReportAttachPdf.
  ///
  /// In en, this message translates to:
  /// **'Attach PDF (optional)'**
  String get addReportAttachPdf;

  /// No description provided for @exportSummaryMarkers.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} markers'**
  String exportSummaryMarkers(int selected, int total);

  /// No description provided for @exportMedicalSub.
  ///
  /// In en, this message translates to:
  /// **'Conditions, allergies & vaccinations ({count} items)'**
  String exportMedicalSub(int count);

  /// No description provided for @reviewHeader.
  ///
  /// In en, this message translates to:
  /// **'We found {count} value(s). Check, edit, and confirm before saving.'**
  String reviewHeader(int count);

  /// No description provided for @bodyMapIntro.
  ///
  /// In en, this message translates to:
  /// **'Your health at a glance. Each region reflects the markers you track for that system.'**
  String get bodyMapIntro;

  /// No description provided for @bodyMapInRange.
  ///
  /// In en, this message translates to:
  /// **'In range'**
  String get bodyMapInRange;

  /// No description provided for @bodyMapNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get bodyMapNoData;

  /// No description provided for @bodyMapNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get bodyMapNoDataYet;

  /// No description provided for @bodyMapEmptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No data yet — log a result in this category to see it here.'**
  String get bodyMapEmptyCategory;

  /// No description provided for @bodyMapAllInRange.
  ///
  /// In en, this message translates to:
  /// **'All {total} in range'**
  String bodyMapAllInRange(int total);

  /// No description provided for @bodyMapOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'{out} of {total} out of range'**
  String bodyMapOutOfRange(int out, int total);

  /// No description provided for @biomarkerDetailRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get biomarkerDetailRangeAll;

  /// No description provided for @biomarkerDetailNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes about this biomarker — context, goals, doctor remarks…'**
  String get biomarkerDetailNotesHint;

  /// No description provided for @scoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Scores'**
  String get scoresTitle;

  /// No description provided for @scoresBiologicalAge.
  ///
  /// In en, this message translates to:
  /// **'Biological Age'**
  String get scoresBiologicalAge;

  /// No description provided for @scoresBiologicalAgeCaps.
  ///
  /// In en, this message translates to:
  /// **'BIOLOGICAL AGE'**
  String get scoresBiologicalAgeCaps;

  /// No description provided for @scoresYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get scoresYears;

  /// No description provided for @scoresPhenoCaption.
  ///
  /// In en, this message translates to:
  /// **'Estimated from 9 blood markers (Levine PhenoAge). Informational only.'**
  String get scoresPhenoCaption;

  /// No description provided for @scoresValuesUsed.
  ///
  /// In en, this message translates to:
  /// **'Values used'**
  String get scoresValuesUsed;

  /// No description provided for @scoresUnusualWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠ Highlighted values look unusual — likely the cause.'**
  String get scoresUnusualWarning;

  /// No description provided for @scoresPhenoLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Estimate your biological age from a standard blood panel (Levine PhenoAge).'**
  String get scoresPhenoLockedBody;

  /// No description provided for @scoresUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Log glucose, lipids & insulin to unlock your scores'**
  String get scoresUnlockHint;

  /// No description provided for @scoresMetabolicHealth.
  ///
  /// In en, this message translates to:
  /// **'Metabolic Health'**
  String get scoresMetabolicHealth;

  /// No description provided for @scoresDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Scores are informational only — not medical advice. They assume fasting samples and standard adult reference cutoffs. Discuss results with a clinician.'**
  String get scoresDisclaimer;

  /// No description provided for @scoresLevelGood.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get scoresLevelGood;

  /// No description provided for @scoresLevelWatch.
  ///
  /// In en, this message translates to:
  /// **'watch'**
  String get scoresLevelWatch;

  /// No description provided for @scoresLevelFlagged.
  ///
  /// In en, this message translates to:
  /// **'flagged'**
  String get scoresLevelFlagged;

  /// No description provided for @scoresActualAge.
  ///
  /// In en, this message translates to:
  /// **'Your actual age is {age}'**
  String scoresActualAge(int age);

  /// No description provided for @scoresNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs: {items}'**
  String scoresNeeds(String items);

  /// No description provided for @scoresAllGood.
  ///
  /// In en, this message translates to:
  /// **'All {count} scores looking good 🎉'**
  String scoresAllGood(int count);

  /// No description provided for @scoresCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} {label}'**
  String scoresCountLabel(int count, String label);

  /// No description provided for @scoresHeadlineFlagged.
  ///
  /// In en, this message translates to:
  /// **'{flags} flagged · {total} computed'**
  String scoresHeadlineFlagged(int flags, int total);

  /// No description provided for @scoresHeadlineWatch.
  ///
  /// In en, this message translates to:
  /// **'{watch} to watch · {total} computed'**
  String scoresHeadlineWatch(int watch, int total);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search biomarkers, reports, notes, tags…'**
  String get searchHint;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// No description provided for @profileHealthDetails.
  ///
  /// In en, this message translates to:
  /// **'Health Details'**
  String get profileHealthDetails;

  /// No description provided for @scanExtractAuto.
  ///
  /// In en, this message translates to:
  /// **'Extract values automatically'**
  String get scanExtractAuto;

  /// No description provided for @scanIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or pick a PDF of your lab report. Everything is processed on your device — nothing is uploaded for scanning. You\'ll review the results before anything is saved.'**
  String get scanIntroBody;

  /// No description provided for @scanOptionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get scanOptionPhoto;

  /// No description provided for @scanOptionPhotoSub.
  ///
  /// In en, this message translates to:
  /// **'Capture the report with your camera'**
  String get scanOptionPhotoSub;

  /// No description provided for @scanOptionImage.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get scanOptionImage;

  /// No description provided for @scanOptionImageSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo from your gallery'**
  String get scanOptionImageSub;

  /// No description provided for @scanOptionPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get scanOptionPdf;

  /// No description provided for @scanOptionPdfSub.
  ///
  /// In en, this message translates to:
  /// **'Scan a PDF lab report'**
  String get scanOptionPdfSub;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search across your biomarkers, reports, and result notes / tags.'**
  String get searchPrompt;

  /// No description provided for @searchSectionEntries.
  ///
  /// In en, this message translates to:
  /// **'Results matching notes / tags'**
  String get searchSectionEntries;

  /// No description provided for @pinnedManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get pinnedManage;

  /// No description provided for @pinnedManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage pinned'**
  String get pinnedManageTitle;

  /// No description provided for @pinnedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing pinned yet.'**
  String get pinnedEmpty;

  /// No description provided for @pdfPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview & share'**
  String get pdfPreviewTitle;

  /// No description provided for @errorNoInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorNoInternetTitle;

  /// No description provided for @errorNoInternetBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your internet connection and try again.'**
  String get errorNoInternetBody;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get errorGenericBody;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
