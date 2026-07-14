// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ITSM Device Registration';

  @override
  String get initializingWorkspace => 'INITIALIZING WORKSPACE...';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get pleaseLoginToContinue => 'Please login to continue';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get home => 'Home';

  @override
  String get menu => 'Menu';

  @override
  String get notifications => 'Notifications';

  @override
  String get welcomeUser => 'Welcome,\nAzher';

  @override
  String get registerDevice => 'Register Device';

  @override
  String get registerDeviceDescription =>
      'Click the button below to register a\nnew device';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get close => 'Close';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionArabic => 'العربية';

  @override
  String get languageCodeEnglish => 'EN';

  @override
  String get languageCodeArabic => 'AR';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get back => 'Back';

  @override
  String get deviceRegistration => 'Device Registration';

  @override
  String get tagNumber => 'Tag Number';

  @override
  String get enterOrSearchTagNumber => 'Enter or search tag number';

  @override
  String get deviceInformation => 'Device Information';

  @override
  String get deviceInformationEmpty =>
      'Device information will appear after tag validation.';

  @override
  String get brand => 'Brand';

  @override
  String get deviceType => 'Device Type';

  @override
  String get status => 'Status';

  @override
  String get assigned => 'Assigned';

  @override
  String get notAssigned => 'Not Assigned';

  @override
  String get assignmentStatus => 'Assignment Status';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get enterSerialNumber => 'Enter serial number';

  @override
  String get serialNumberFromDevice => 'Loaded from selected device';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get enterEmployeeId => 'Enter employee ID';

  @override
  String get searchTagNumber => 'Search tag number';

  @override
  String get searchEmployeeId => 'Search employee ID';

  @override
  String get invalidTagNumber => 'Enter a valid tag number.';

  @override
  String get invalidSerialNumber => 'Enter a valid serial number.';

  @override
  String get invalidEmployeeId => 'Enter a valid employee ID.';

  @override
  String get employeeInformation => 'Employee Information';

  @override
  String get employeeInformationEmpty =>
      'Employee information will appear after ID validation.';

  @override
  String get employeeName => 'Employee Name';

  @override
  String get email => 'Email';

  @override
  String get organization => 'Organization / Department';

  @override
  String get phone => 'Phone';

  @override
  String get jobTitle => 'Function / Job Title';

  @override
  String get assignedEmployee => 'Assigned employee';

  @override
  String get notAvailable => 'Not available';

  @override
  String get deviceLookupFailed =>
      'Device not found. Check the tag number and try again.';

  @override
  String get deviceLookupTimeout =>
      'Device lookup timed out. Please try again.';

  @override
  String get employeeLookupFailed =>
      'Employee not found. Check the employee ID and try again.';

  @override
  String get department => 'Department';

  @override
  String get location => 'Location';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get addAssignment => 'Add Assignment';

  @override
  String get removeAssignment => 'Remove Assignment';

  @override
  String get addAssignmentConfirmation =>
      'Are you sure you want to assign this device to the selected employee?';

  @override
  String get removeAssignmentConfirmation =>
      'Are you sure you want to remove this employee from the device?';

  @override
  String get assignmentAddedSuccessfully => 'Assignment added successfully.';

  @override
  String get assignmentRemovedSuccessfully =>
      'Assignment removed successfully.';

  @override
  String get assignmentAddFailure =>
      'Unable to add the assignment. Please try again.';

  @override
  String get assignmentRemovalFailure =>
      'Unable to remove the assignment. Please try again.';

  @override
  String get confirmSubmission => 'Confirm Submission';

  @override
  String get submitConfirmationMessage =>
      'Are you sure you want to submit the registration?';

  @override
  String get initializingCamera => 'Initializing camera...';

  @override
  String get cameraPermissionDenied =>
      'Camera permission is required to scan barcodes.';

  @override
  String get cameraUnavailable =>
      'Camera is unavailable. Use manual entry instead.';

  @override
  String get flash => 'Flash';

  @override
  String get alignBarcode => 'Align the barcode within\nthe frame to scan';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get manualTagEntry => 'Enter Tag Number';

  @override
  String get enterTagNumber => 'Enter a tag number';

  @override
  String get success => 'Success!';

  @override
  String get deviceRegisteredSuccessfully =>
      'The device has been registered\nsuccessfully.';

  @override
  String get backToDeviceRegistration => 'Back to Device Registration';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get loginFooter => '© ITSM – Center for Information Systems';
}
