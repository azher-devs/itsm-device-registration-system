// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تسجيل أجهزة ITSM';

  @override
  String get initializingWorkspace => 'جاري تهيئة مساحة العمل...';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get pleaseLoginToContinue => 'يرجى تسجيل الدخول للمتابعة';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get home => 'الرئيسية';

  @override
  String get menu => 'القائمة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get welcomeUser => 'مرحبًا،\nAzher';

  @override
  String get registerDevice => 'تسجيل جهاز';

  @override
  String get registerDeviceDescription =>
      'اضغط على الزر أدناه لتسجيل\nجهاز جديد';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get close => 'إغلاق';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionArabic => 'العربية';

  @override
  String get languageCodeEnglish => 'EN';

  @override
  String get languageCodeArabic => 'AR';

  @override
  String get appearance => 'المظهر';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get back => 'رجوع';

  @override
  String get deviceRegistration => 'تسجيل الجهاز';

  @override
  String get tagNumber => 'رقم الجهاز';

  @override
  String get enterOrSearchTagNumber => 'أدخل أو ابحث عن رقم الجهاز';

  @override
  String get deviceInformation => 'معلومات الجهاز';

  @override
  String get deviceInformationEmpty =>
      'ستظهر معلومات الجهاز بعد التحقق من الرقم.';

  @override
  String get brand => 'العلامة التجارية';

  @override
  String get deviceType => 'نوع الجهاز';

  @override
  String get status => 'الحالة';

  @override
  String get assigned => 'مخصص';

  @override
  String get notAssigned => 'غير مخصص';

  @override
  String get assignmentStatus => 'حالة العهدة';

  @override
  String get serialNumber => 'الرقم التسلسلي';

  @override
  String get enterSerialNumber => 'أدخل الرقم التسلسلي';

  @override
  String get serialNumberFromDevice => 'يتم تحميله من الجهاز المحدد';

  @override
  String get employeeId => 'الرقم الوظيفي';

  @override
  String get enterEmployeeId => 'أدخل الرقم الوظيفي';

  @override
  String get searchTagNumber => 'البحث عن رقم الجهاز';

  @override
  String get searchEmployeeId => 'البحث عن الرقم الوظيفي';

  @override
  String get invalidTagNumber => 'أدخل رقم جهاز صحيحًا.';

  @override
  String get invalidSerialNumber => 'أدخل رقمًا تسلسليًا صحيحًا.';

  @override
  String get invalidEmployeeId => 'أدخل رقمًا وظيفيًا صحيحًا.';

  @override
  String get employeeInformation => 'معلومات الموظف';

  @override
  String get employeeInformationEmpty =>
      'ستظهر معلومات الموظف بعد التحقق من الرقم الوظيفي.';

  @override
  String get employeeName => 'اسم الموظف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get organization => 'المؤسسة';

  @override
  String get phone => 'الهاتف';

  @override
  String get jobTitle => 'المسمى الوظيفي';

  @override
  String get assignedEmployee => 'الموظف المخصص';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get deviceLookupFailed =>
      'لم يتم العثور على الجهاز. تحقق من رقم الجهاز وحاول مرة أخرى.';

  @override
  String get deviceLookupTimeout =>
      'انتهت مهلة البحث عن الجهاز. يرجى المحاولة مرة أخرى.';

  @override
  String get employeeLookupFailed =>
      'لم يتم العثور على الموظف. تحقق من الرقم الوظيفي وحاول مرة أخرى.';

  @override
  String get department => 'القسم';

  @override
  String get location => 'الموقع';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get submit => 'إرسال';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get add => 'إضافة';

  @override
  String get remove => 'إزالة';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get assignDevice => 'تخصيص الجهاز';

  @override
  String get assignDeviceConfirmation =>
      'هل أنت متأكد أنك تريد تخصيص هذا الجهاز؟';

  @override
  String get removeDeviceAssignmentConfirmation =>
      'هل أنت متأكد أنك تريد إزالة هذا الموظف من هذا الجهاز؟';

  @override
  String get addAssignment => 'إضافة العهدة';

  @override
  String get removeAssignment => 'إزالة العهدة';

  @override
  String get addAssignmentConfirmation =>
      'هل أنت متأكد أنك تريد ربط هذا الجهاز بالموظف المحدد؟';

  @override
  String get removeAssignmentConfirmation =>
      'هل أنت متأكد أنك تريد إزالة هذا الموظف من الجهاز؟';

  @override
  String get assignmentAddedSuccessfully => 'تم تخصيص الجهاز بنجاح.';

  @override
  String get assignmentRemovedSuccessfully =>
      'تمت إزالة الموظف من الجهاز بنجاح.';

  @override
  String get assignmentAddFailure =>
      'تعذرت إضافة العهدة. يرجى المحاولة مرة أخرى.';

  @override
  String get assignmentRemovalFailure =>
      'تعذرت إزالة العهدة. يرجى المحاولة مرة أخرى.';

  @override
  String get confirmSubmission => 'تأكيد الإرسال';

  @override
  String get submitConfirmationMessage =>
      'هل أنت متأكد أنك تريد إرسال التسجيل؟';

  @override
  String get initializingCamera => 'جاري تهيئة الكاميرا...';

  @override
  String get cameraPermissionDenied => 'إذن الكاميرا مطلوب لمسح الباركود.';

  @override
  String get cameraUnavailable =>
      'الكاميرا غير متاحة. استخدم الإدخال اليدوي بدلاً من ذلك.';

  @override
  String get flash => 'الفلاش';

  @override
  String get alignBarcode => 'ضع الباركود داخل\nالإطار للمسح';

  @override
  String get scanFromGallery => 'المسح من المعرض';

  @override
  String get noBarcodeFoundTitle => 'لم يتم العثور على باركود';

  @override
  String get noBarcodeFoundMessage =>
      'لم يتم العثور على باركود في الصورة المحددة.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get useCamera => 'استخدام الكاميرا';

  @override
  String get galleryPermissionTitle => 'مطلوب إذن الوصول إلى الصور';

  @override
  String get galleryPermissionMessage =>
      'اسمح بالوصول إلى الصور لاختيار صورة ومسح الباركود منها.';

  @override
  String get galleryScanFailed => 'تعذر مسح الصورة المحددة. حاول مرة أخرى.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get copy => 'نسخ';

  @override
  String get tagNumberCopied => 'تم نسخ رقم الجهاز';

  @override
  String get serialNumberCopied => 'تم نسخ الرقم التسلسلي';

  @override
  String get employeeIdCopied => 'تم نسخ الرقم الوظيفي';

  @override
  String get manualEntry => 'إدخال يدوي';

  @override
  String get manualTagEntry => 'إدخال رقم الجهاز';

  @override
  String get enterTagNumber => 'أدخل رقم الجهاز';

  @override
  String get success => 'تم بنجاح!';

  @override
  String get deviceRegisteredSuccessfully => 'تم تسجيل الجهاز\nبنجاح.';

  @override
  String get backToDeviceRegistration => 'الرجوع إلى التسجيل';

  @override
  String get backToHome => 'الرجوع إلى الرئيسية';

  @override
  String get loginFooter => '© ITSM – مركز نظم المعلومات';
}
