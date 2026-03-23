import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Vee'**
  String get appName;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @payee.
  ///
  /// In en, this message translates to:
  /// **'Payee'**
  String get payee;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @pleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'Please select'**
  String get pleaseSelect;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @scanReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or select from gallery\nto automatically recognize receipt'**
  String get scanReceiptHint;

  /// No description provided for @ocrProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing image...'**
  String get ocrProcessing;

  /// No description provided for @ocrSuccess.
  ///
  /// In en, this message translates to:
  /// **'Text recognized successfully'**
  String get ocrSuccess;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to recognize text'**
  String get ocrFailed;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @parentCategory.
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get parentCategory;

  /// No description provided for @subcategories.
  ///
  /// In en, this message translates to:
  /// **'Subcategories'**
  String get subcategories;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get addBill;

  /// No description provided for @billName.
  ///
  /// In en, this message translates to:
  /// **'Bill Name'**
  String get billName;

  /// No description provided for @billAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get billAmount;

  /// No description provided for @billDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get billDate;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @nextBill.
  ///
  /// In en, this message translates to:
  /// **'Next Bill'**
  String get nextBill;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @dueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due Soon'**
  String get dueSoon;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMember;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @shareTransactions.
  ///
  /// In en, this message translates to:
  /// **'Share Transactions'**
  String get shareTransactions;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not Synced'**
  String get notSynced;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String lastSynced(String time);

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirm;

  /// No description provided for @deleteThisRecord.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
  String get deleteThisRecord;

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

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get chooseFromLibrary;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email Verified'**
  String get emailVerified;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email Not Verified'**
  String get emailNotVerified;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent'**
  String get verificationSent;

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get resendVerification;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful, please login again'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Reset password email sent'**
  String get resetPasswordSent;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @transactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Transaction added successfully'**
  String get transactionAdded;

  /// No description provided for @transactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated successfully'**
  String get transactionUpdated;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully'**
  String get transactionDeleted;

  /// No description provided for @incomeAmount.
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String incomeAmount(String amount);

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'-{amount}'**
  String expenseAmount(String amount);

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get totalExpense;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @surplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @deficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get deficit;

  /// No description provided for @noBills.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBills;

  /// No description provided for @billPaid.
  ///
  /// In en, this message translates to:
  /// **'Bill paid'**
  String get billPaid;

  /// No description provided for @billUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Bill unpaid'**
  String get billUnpaid;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @markAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unpaid'**
  String get markAsUnpaid;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind Me'**
  String get remindMe;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderSet;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroups;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get createNewGroup;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCode;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Invite Code'**
  String get enterInviteCode;

  /// No description provided for @copyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Invite Code'**
  String get copyInviteCode;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard'**
  String get inviteCodeCopied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission'**
  String get cameraPermission;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storagePermission;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard?'**
  String get unsavedChanges;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditing;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please login again.'**
  String get unauthorized;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get forbidden;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait.'**
  String get tooManyRequests;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'System maintenance. Please try again later.'**
  String get maintenance;

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// No description provided for @dataStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'Data is stored only on this device'**
  String get dataStoredLocally;

  /// No description provided for @loginBenefits.
  ///
  /// In en, this message translates to:
  /// **'Login Benefits'**
  String get loginBenefits;

  /// No description provided for @syncDataMultipleDevices.
  ///
  /// In en, this message translates to:
  /// **'Sync data across multiple devices'**
  String get syncDataMultipleDevices;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup for peace of mind'**
  String get cloudBackup;

  /// No description provided for @shareWithFamily.
  ///
  /// In en, this message translates to:
  /// **'Share finances with family or partner'**
  String get shareWithFamily;

  /// No description provided for @aiUsageManagement.
  ///
  /// In en, this message translates to:
  /// **'AI usage management'**
  String get aiUsageManagement;

  /// No description provided for @loginOrRegister.
  ///
  /// In en, this message translates to:
  /// **'Login / Register'**
  String get loginOrRegister;

  /// No description provided for @localData.
  ///
  /// In en, this message translates to:
  /// **'Local Data'**
  String get localData;

  /// No description provided for @recordCount.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordCount;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @myPage.
  ///
  /// In en, this message translates to:
  /// **'My Page'**
  String get myPage;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSettings;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSettings;

  /// No description provided for @aboutVee.
  ///
  /// In en, this message translates to:
  /// **'About Vee'**
  String get aboutVee;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @loadMoreData.
  ///
  /// In en, this message translates to:
  /// **'Load More Data'**
  String get loadMoreData;

  /// No description provided for @cancelDelete.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelDelete;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleting;

  /// No description provided for @recordCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recording completed!'**
  String get recordCompleted;

  /// No description provided for @categoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get categoryLoading;

  /// No description provided for @categoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String categoryLoadError(String error);

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @chooseAgain.
  ///
  /// In en, this message translates to:
  /// **'Choose Again'**
  String get chooseAgain;

  /// No description provided for @addDetail.
  ///
  /// In en, this message translates to:
  /// **'Add Detail'**
  String get addDetail;

  /// No description provided for @cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelConfirm;

  /// No description provided for @confirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmConfirm;

  /// No description provided for @layoutUpdated.
  ///
  /// In en, this message translates to:
  /// **'Layout updated'**
  String get layoutUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(String error);

  /// No description provided for @permissionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Permission updated, pushed to user devices in real time'**
  String get permissionUpdated;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed(String error);

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// No description provided for @removeThis.
  ///
  /// In en, this message translates to:
  /// **'Remove This'**
  String get removeThis;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @selectMonthYear.
  ///
  /// In en, this message translates to:
  /// **'Select Month/Year'**
  String get selectMonthYear;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @monthReset.
  ///
  /// In en, this message translates to:
  /// **'Resets on {date}'**
  String monthReset(String date);

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Used {count} time} other{Used {count} times}}'**
  String used(int count);

  /// No description provided for @totalQuota.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Total {count} time/month} other{Total {count} times/month}}'**
  String totalQuota(int count);

  /// No description provided for @aiUsageQuota.
  ///
  /// In en, this message translates to:
  /// **'AI Usage Quota'**
  String get aiUsageQuota;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @telegramBind.
  ///
  /// In en, this message translates to:
  /// **'Telegram Binding'**
  String get telegramBind;

  /// No description provided for @bound.
  ///
  /// In en, this message translates to:
  /// **'Bound'**
  String get bound;

  /// No description provided for @unbound.
  ///
  /// In en, this message translates to:
  /// **'Not Bound'**
  String get unbound;

  /// No description provided for @boundWithTelegram.
  ///
  /// In en, this message translates to:
  /// **'Bound with Telegram #{id}'**
  String boundWithTelegram(String id);

  /// No description provided for @quotaSharedAfterBind.
  ///
  /// In en, this message translates to:
  /// **'After binding, Bot and App share the same AI quota for unified management'**
  String get quotaSharedAfterBind;

  /// No description provided for @bindTelegram.
  ///
  /// In en, this message translates to:
  /// **'Bind Telegram'**
  String get bindTelegram;

  /// No description provided for @bindTelegramDesc.
  ///
  /// In en, this message translates to:
  /// **'Bind to share AI quota between Bot download/recognition and App'**
  String get bindTelegramDesc;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @validFor10Minutes.
  ///
  /// In en, this message translates to:
  /// **'Valid for 10 minutes'**
  String get validFor10Minutes;

  /// No description provided for @sendBindCommand.
  ///
  /// In en, this message translates to:
  /// **'Go to Telegram Bot and send:\n/bind {code}'**
  String sendBindCommand(String code);

  /// No description provided for @refreshCode.
  ///
  /// In en, this message translates to:
  /// **'Refresh Code'**
  String get refreshCode;

  /// No description provided for @applyBindCode.
  ///
  /// In en, this message translates to:
  /// **'Get Bind Code'**
  String get applyBindCode;

  /// No description provided for @unbind.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get unbind;

  /// No description provided for @telegramConnection.
  ///
  /// In en, this message translates to:
  /// **'Telegram Connection'**
  String get telegramConnection;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @receiptImages.
  ///
  /// In en, this message translates to:
  /// **'Receipt Images'**
  String get receiptImages;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @fromSource.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String fromSource(String source);

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @notEntered.
  ///
  /// In en, this message translates to:
  /// **'Not entered'**
  String get notEntered;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @itemsTotal.
  ///
  /// In en, this message translates to:
  /// **'Items Total'**
  String get itemsTotal;

  /// No description provided for @totalRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records} =1{1 record} other{{count} records}}'**
  String totalRecords(int count);

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword'**
  String get tryDifferentKeyword;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin Console'**
  String get adminConsole;

  /// No description provided for @dataDashboard.
  ///
  /// In en, this message translates to:
  /// **'Data Dashboard'**
  String get dataDashboard;

  /// No description provided for @systemConfig.
  ///
  /// In en, this message translates to:
  /// **'System Config'**
  String get systemConfig;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @userOverview.
  ///
  /// In en, this message translates to:
  /// **'User Overview'**
  String get userOverview;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @adminCount.
  ///
  /// In en, this message translates to:
  /// **'Admin Count'**
  String get adminCount;

  /// No description provided for @wsOnline.
  ///
  /// In en, this message translates to:
  /// **'WS Online'**
  String get wsOnline;

  /// No description provided for @billOverview.
  ///
  /// In en, this message translates to:
  /// **'Bill Overview'**
  String get billOverview;

  /// No description provided for @totalBills.
  ///
  /// In en, this message translates to:
  /// **'Total Bills'**
  String get totalBills;

  /// No description provided for @billsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Bills This Month'**
  String get billsThisMonth;

  /// No description provided for @aiUsageThisMonth.
  ///
  /// In en, this message translates to:
  /// **'AI Usage This Month'**
  String get aiUsageThisMonth;

  /// No description provided for @aiUsageCountTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} time} other{{count} times}}'**
  String aiUsageCountTimes(num count);

  /// No description provided for @wsConnections.
  ///
  /// In en, this message translates to:
  /// **'WS Connections'**
  String get wsConnections;

  /// No description provided for @configValue.
  ///
  /// In en, this message translates to:
  /// **'Config Value'**
  String get configValue;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'(Empty)'**
  String get empty;

  /// No description provided for @searchEmailUsername.
  ///
  /// In en, this message translates to:
  /// **'Search email / username / nickname'**
  String get searchEmailUsername;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @banned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get banned;

  /// No description provided for @configPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission Config'**
  String get configPermission;

  /// No description provided for @botText.
  ///
  /// In en, this message translates to:
  /// **'Bot Text'**
  String get botText;

  /// No description provided for @botReceipt.
  ///
  /// In en, this message translates to:
  /// **'Bot Receipt'**
  String get botReceipt;

  /// No description provided for @botVoice.
  ///
  /// In en, this message translates to:
  /// **'Bot Voice'**
  String get botVoice;

  /// No description provided for @botDownload.
  ///
  /// In en, this message translates to:
  /// **'Bot Download'**
  String get botDownload;

  /// No description provided for @appOcr.
  ///
  /// In en, this message translates to:
  /// **'App OCR'**
  String get appOcr;

  /// No description provided for @appExport.
  ///
  /// In en, this message translates to:
  /// **'App Export'**
  String get appExport;

  /// No description provided for @appUpload.
  ///
  /// In en, this message translates to:
  /// **'App Upload'**
  String get appUpload;

  /// No description provided for @botTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Bot Text Entry'**
  String get botTextLabel;

  /// No description provided for @botReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Bot Image Recognition'**
  String get botReceiptLabel;

  /// No description provided for @botVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Bot Voice Entry'**
  String get botVoiceLabel;

  /// No description provided for @botDownloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Bot Download'**
  String get botDownloadLabel;

  /// No description provided for @appOcrLabel.
  ///
  /// In en, this message translates to:
  /// **'App OCR Recognition'**
  String get appOcrLabel;

  /// No description provided for @appExportLabel.
  ///
  /// In en, this message translates to:
  /// **'App Data Export'**
  String get appExportLabel;

  /// No description provided for @appUploadLabel.
  ///
  /// In en, this message translates to:
  /// **'App Image Upload'**
  String get appUploadLabel;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @savePermission.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save Permission (1 item)} other{Save Permission ({count} items)}}'**
  String savePermission(int count);

  /// No description provided for @registrationIp.
  ///
  /// In en, this message translates to:
  /// **'Reg IP: {ip}'**
  String registrationIp(String ip);

  /// No description provided for @lastIp.
  ///
  /// In en, this message translates to:
  /// **'Last IP: {ip}'**
  String lastIp(String ip);

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'No Permission'**
  String get noPermission;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsLabel;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountGreaterThanZero;

  /// No description provided for @calculatedFromTotal.
  ///
  /// In en, this message translates to:
  /// **'Calculated from total'**
  String get calculatedFromTotal;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @invalidAmountForItem.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount for item {num}'**
  String invalidAmountForItem(int num);

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional info...'**
  String get additionalInfo;

  /// No description provided for @notEnteredYet.
  ///
  /// In en, this message translates to:
  /// **'(Not entered)'**
  String get notEnteredYet;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String records(int count);

  /// No description provided for @expenseTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get expenseTotal;

  /// No description provided for @smartBillAssistant.
  ///
  /// In en, this message translates to:
  /// **'Smart Bill Assistant'**
  String get smartBillAssistant;

  /// No description provided for @usernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get usernameOrEmail;

  /// No description provided for @enterUsernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter username or email'**
  String get enterUsernameOrEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get enterPassword;

  /// No description provided for @defaultCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get defaultCategory;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {error}'**
  String imageUploadFailed(String error);

  /// No description provided for @monthDayFormat.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String monthDayFormat(int month, int day);

  /// No description provided for @quotaResetsOn.
  ///
  /// In en, this message translates to:
  /// **'{date} reset'**
  String quotaResetsOn(String date);

  /// No description provided for @yearMonthFormat.
  ///
  /// In en, this message translates to:
  /// **'{year}{month}'**
  String yearMonthFormat(int year, int month);

  /// No description provided for @monthDayJapaneseFormat.
  ///
  /// In en, this message translates to:
  /// **'{month}{day}'**
  String monthDayJapaneseFormat(int month, int day);

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enter6DigitCode;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @enterRegisteredEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter registered email'**
  String get enterRegisteredEmail;

  /// No description provided for @willSendResetCode.
  ///
  /// In en, this message translates to:
  /// **'A password reset code will be sent'**
  String get willSendResetCode;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @verificationSentTo.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to {email}'**
  String verificationSentTo(String email);

  /// No description provided for @sixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get sixDigitCode;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset'**
  String get confirmReset;

  /// No description provided for @resendCodeWithCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeWithCountdown(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailed;

  /// No description provided for @usernameFormat.
  ///
  /// In en, this message translates to:
  /// **'Username format'**
  String get usernameFormat;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinLength;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid username'**
  String get usernameInvalid;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a number'**
  String get passwordNeedsNumber;

  /// No description provided for @passwordNeedsLetter.
  ///
  /// In en, this message translates to:
  /// **'Password must contain a letter'**
  String get passwordNeedsLetter;

  /// No description provided for @registerAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service'**
  String get registerAgree;

  /// No description provided for @checkVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Check Verification Code'**
  String get checkVerificationCode;

  /// No description provided for @verifyAndActivate.
  ///
  /// In en, this message translates to:
  /// **'Verify and Activate'**
  String get verifyAndActivate;

  /// No description provided for @didNotReceiveResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive it? Resend'**
  String get didNotReceiveResend;

  /// No description provided for @changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Change password failed'**
  String get changePasswordFailed;

  /// No description provided for @nicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Nickname is required'**
  String get nicknameRequired;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @usernameEmailCannotChange.
  ///
  /// In en, this message translates to:
  /// **'Username and email cannot be changed'**
  String get usernameEmailCannotChange;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Please contact administrator'**
  String get contactAdmin;

  /// No description provided for @noAiPermission.
  ///
  /// In en, this message translates to:
  /// **'No AI Recognition Permission'**
  String get noAiPermission;

  /// No description provided for @contactAdminForOcr.
  ///
  /// In en, this message translates to:
  /// **'Please contact admin to enable \"App OCR\" feature'**
  String get contactAdminForOcr;

  /// No description provided for @noUploadPermission.
  ///
  /// In en, this message translates to:
  /// **'No permission to upload receipt images'**
  String get noUploadPermission;

  /// No description provided for @myLedger.
  ///
  /// In en, this message translates to:
  /// **'My Ledger'**
  String get myLedger;
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
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
