import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ITSM Device Registration'**
  String get appTitle;

  /// No description provided for @initializingWorkspace.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZING WORKSPACE...'**
  String get initializingWorkspace;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @pleaseLoginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get pleaseLoginToContinue;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome,\nAzher'**
  String get welcomeUser;

  /// No description provided for @registerDevice.
  ///
  /// In en, this message translates to:
  /// **'Register Device'**
  String get registerDevice;

  /// No description provided for @registerDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to register a\nnew device'**
  String get registerDeviceDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @languageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageOptionEnglish;

  /// No description provided for @languageOptionArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageOptionArabic;

  /// No description provided for @languageCodeEnglish.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageCodeEnglish;

  /// No description provided for @languageCodeArabic.
  ///
  /// In en, this message translates to:
  /// **'AR'**
  String get languageCodeArabic;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @deviceRegistration.
  ///
  /// In en, this message translates to:
  /// **'Device Registration'**
  String get deviceRegistration;

  /// No description provided for @tagNumber.
  ///
  /// In en, this message translates to:
  /// **'Tag Number'**
  String get tagNumber;

  /// No description provided for @enterOrSearchTagNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter or search tag number'**
  String get enterOrSearchTagNumber;

  /// No description provided for @deviceInformation.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInformation;

  /// No description provided for @deviceInformationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Device information will appear after tag validation.'**
  String get deviceInformationEmpty;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @deviceType.
  ///
  /// In en, this message translates to:
  /// **'Device Type'**
  String get deviceType;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// No description provided for @assignmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Assignment Status'**
  String get assignmentStatus;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @enterSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter serial number'**
  String get enterSerialNumber;

  /// No description provided for @serialNumberFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Loaded from selected device'**
  String get serialNumberFromDevice;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @enterEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Enter employee ID'**
  String get enterEmployeeId;

  /// No description provided for @searchTagNumber.
  ///
  /// In en, this message translates to:
  /// **'Search tag number'**
  String get searchTagNumber;

  /// No description provided for @searchEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Search employee ID'**
  String get searchEmployeeId;

  /// No description provided for @invalidTagNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid tag number.'**
  String get invalidTagNumber;

  /// No description provided for @invalidSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid serial number.'**
  String get invalidSerialNumber;

  /// No description provided for @invalidEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid employee ID.'**
  String get invalidEmployeeId;

  /// No description provided for @employeeInformation.
  ///
  /// In en, this message translates to:
  /// **'Employee Information'**
  String get employeeInformation;

  /// No description provided for @employeeInformationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Employee information will appear after ID validation.'**
  String get employeeInformationEmpty;

  /// No description provided for @employeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get employeeName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization / Department'**
  String get organization;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Function / Job Title'**
  String get jobTitle;

  /// No description provided for @assignedEmployee.
  ///
  /// In en, this message translates to:
  /// **'Assigned employee'**
  String get assignedEmployee;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @deviceLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Device not found. Check the tag number and try again.'**
  String get deviceLookupFailed;

  /// No description provided for @deviceLookupTimeout.
  ///
  /// In en, this message translates to:
  /// **'Device lookup timed out. Please try again.'**
  String get deviceLookupTimeout;

  /// No description provided for @employeeLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Employee not found. Check the employee ID and try again.'**
  String get employeeLookupFailed;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @assignDevice.
  ///
  /// In en, this message translates to:
  /// **'Assign Device'**
  String get assignDevice;

  /// No description provided for @assignDeviceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to assign this device?'**
  String get assignDeviceConfirmation;

  /// No description provided for @removeDeviceAssignmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this employee from this device?'**
  String get removeDeviceAssignmentConfirmation;

  /// No description provided for @addAssignment.
  ///
  /// In en, this message translates to:
  /// **'Add Assignment'**
  String get addAssignment;

  /// No description provided for @removeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Remove Assignment'**
  String get removeAssignment;

  /// No description provided for @addAssignmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to assign this device to the selected employee?'**
  String get addAssignmentConfirmation;

  /// No description provided for @removeAssignmentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this employee from the device?'**
  String get removeAssignmentConfirmation;

  /// No description provided for @assignmentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'The device has been assigned successfully.'**
  String get assignmentAddedSuccessfully;

  /// No description provided for @assignmentRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee removed from the device successfully.'**
  String get assignmentRemovedSuccessfully;

  /// No description provided for @assignmentAddFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to add the assignment. Please try again.'**
  String get assignmentAddFailure;

  /// No description provided for @assignmentRemovalFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove the assignment. Please try again.'**
  String get assignmentRemovalFailure;

  /// No description provided for @confirmSubmission.
  ///
  /// In en, this message translates to:
  /// **'Confirm Submission'**
  String get confirmSubmission;

  /// No description provided for @submitConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit the registration?'**
  String get submitConfirmationMessage;

  /// No description provided for @initializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get initializingCamera;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan barcodes.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable. Use manual entry instead.'**
  String get cameraUnavailable;

  /// No description provided for @flash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get flash;

  /// No description provided for @alignBarcode.
  ///
  /// In en, this message translates to:
  /// **'Align the barcode within\nthe frame to scan'**
  String get alignBarcode;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @manualTagEntry.
  ///
  /// In en, this message translates to:
  /// **'Enter Tag Number'**
  String get manualTagEntry;

  /// No description provided for @enterTagNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag number'**
  String get enterTagNumber;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @deviceRegisteredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'The device has been registered\nsuccessfully.'**
  String get deviceRegisteredSuccessfully;

  /// No description provided for @backToDeviceRegistration.
  ///
  /// In en, this message translates to:
  /// **'Back to Device Registration'**
  String get backToDeviceRegistration;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @loginFooter.
  ///
  /// In en, this message translates to:
  /// **'© ITSM – Center for Information Systems'**
  String get loginFooter;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
