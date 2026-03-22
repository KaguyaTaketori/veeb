// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Vee';

  @override
  String get transactions => '取引';

  @override
  String get record => '記録';

  @override
  String get stats => '統計';

  @override
  String get profile => 'マイページ';

  @override
  String get admin => '管理';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get add => '追加';

  @override
  String get search => '検索';

  @override
  String get noData => 'データなし';

  @override
  String get login => 'ログイン';

  @override
  String get logout => 'ログアウト';

  @override
  String get register => '登録';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get forgotPassword => 'パスワードを忘れた場合';

  @override
  String get dontHaveAccount => 'アカウントをお持ちでない方';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちの方';

  @override
  String get signUp => '新規登録';

  @override
  String get signIn => 'ログイン';

  @override
  String get income => '収入';

  @override
  String get expense => '支出';

  @override
  String get transfer => '振替';

  @override
  String get amount => '金額';

  @override
  String get category => 'カテゴリー';

  @override
  String get account => '口座';

  @override
  String get date => '日付';

  @override
  String get note => 'メモ';

  @override
  String get description => '説明';

  @override
  String get total => '合計';

  @override
  String get balance => '残高';

  @override
  String get submit => '送信';

  @override
  String get success => '成功';

  @override
  String get failed => '失敗';

  @override
  String get pleaseSelect => '選択してください';

  @override
  String get required => '必須';

  @override
  String get invalidEmail => '無効なメールアドレスです';

  @override
  String get passwordTooShort => 'パスワードは6文字以上必要です';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageSettings => '言語設定';

  @override
  String get currency => '通貨';

  @override
  String get theme => 'テーマ';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get systemTheme => 'システム設定';

  @override
  String get camera => 'カメラ';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get scanReceipt => 'レシートをスキャン';

  @override
  String get scanReceiptHint => '写真を撮るかギャラリーから選択\nレシート情報を自動認識';

  @override
  String get ocrProcessing => '画像を処理中...';

  @override
  String get ocrSuccess => '文字認識に成功しました';

  @override
  String get ocrFailed => '文字認識に失敗しました';

  @override
  String get thisMonth => '今月';

  @override
  String get lastMonth => '先月';

  @override
  String get thisYear => '今年';

  @override
  String get custom => 'カスタム';

  @override
  String get from => '開始';

  @override
  String get to => '終了';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get thisWeek => '今週';

  @override
  String get categories => 'カテゴリー';

  @override
  String get accounts => '口座';

  @override
  String get createAccount => '口座を作成';

  @override
  String get accountName => '口座名';

  @override
  String get initialBalance => '初期残高';

  @override
  String get createCategory => 'カテゴリーを作成';

  @override
  String get categoryName => 'カテゴリー名';

  @override
  String get icon => 'アイコン';

  @override
  String get color => '色';

  @override
  String get parentCategory => '親カテゴリー';

  @override
  String get subcategories => 'サブカテゴリー';

  @override
  String get bills => '請求書';

  @override
  String get recurring => '定期';

  @override
  String get addBill => '請求書を追加';

  @override
  String get billName => '請求書名';

  @override
  String get billAmount => '金額';

  @override
  String get billDate => '日付';

  @override
  String get frequency => '頻度';

  @override
  String get daily => '毎日';

  @override
  String get weekly => '毎週';

  @override
  String get monthly => '毎月';

  @override
  String get yearly => '毎年';

  @override
  String get nextBill => '次回請求';

  @override
  String get paid => '支払済';

  @override
  String get unpaid => '未払い';

  @override
  String get overdue => '期限超過';

  @override
  String get dueSoon => 'まもなく期限';

  @override
  String get group => 'グループ';

  @override
  String get groups => 'グループ';

  @override
  String get createGroup => 'グループを作成';

  @override
  String get groupName => 'グループ名';

  @override
  String get members => 'メンバー';

  @override
  String get inviteMember => 'メンバーを招待';

  @override
  String get removeMember => 'メンバーを削除';

  @override
  String get leaveGroup => 'グループを退出';

  @override
  String get deleteGroup => 'グループを削除';

  @override
  String get shareTransactions => '取引を共有';

  @override
  String get syncStatus => '同期状態';

  @override
  String get synced => '同期済';

  @override
  String get notSynced => '未同期';

  @override
  String get syncing => '同期中...';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String lastSynced(String time) {
    return '最終同期: $time';
  }

  @override
  String get confirmDelete => '本当に削除しますか？';

  @override
  String get deleteConfirm => '削除確認';

  @override
  String get deleteThisRecord => 'この記録を削除しますか？';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get ok => 'OK';

  @override
  String get done => '完了';

  @override
  String get close => '閉じる';

  @override
  String get back => '戻る';

  @override
  String get next => '次へ';

  @override
  String get finish => '完了';

  @override
  String get skip => 'スキップ';

  @override
  String get continueText => '続ける';

  @override
  String get welcome => 'ようこそ';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String get getStarted => '始める';

  @override
  String get username => 'ユーザー名';

  @override
  String get fullName => '氏名';

  @override
  String get phone => '電話番号';

  @override
  String get changePassword => 'パスワード変更';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmNewPassword => '新しいパスワード確認';

  @override
  String get oldPassword => '以前のパスワード';

  @override
  String get passwordChanged => 'パスワードが変更されました';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get removePhoto => '写真を削除';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get chooseFromLibrary => 'ライブラリから選択';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get profileUpdated => 'プロフィールが更新されました';

  @override
  String get emailVerified => 'メール確認済';

  @override
  String get emailNotVerified => 'メール未確認';

  @override
  String get verifyEmail => 'メールを確認';

  @override
  String get verificationEmailSent => '確認メールを送信しました';

  @override
  String get verificationSent => '確認コードを再送信しました';

  @override
  String get resendVerification => '確認メールを再送信';

  @override
  String get resetPassword => 'パスワードをリセット';

  @override
  String get resetPasswordTitle => 'パスワードをリセット';

  @override
  String get resetPasswordSuccess => 'パスワードがリセットされました。もう一度ログインしてください。';

  @override
  String get resetPasswordSent => 'リセットメールを送信しました';

  @override
  String get noTransactions => '取引がありません';

  @override
  String get addTransaction => '取引を追加';

  @override
  String get editTransaction => '取引を編集';

  @override
  String get deleteTransaction => '取引を削除';

  @override
  String get transactionAdded => '取引が追加されました';

  @override
  String get transactionUpdated => '取引が更新されました';

  @override
  String get transactionDeleted => '取引が削除されました';

  @override
  String incomeAmount(String amount) {
    return '+$amount';
  }

  @override
  String expenseAmount(String amount) {
    return '-$amount';
  }

  @override
  String get totalIncome => '総収入';

  @override
  String get totalExpense => '総支出';

  @override
  String get netBalance => '純残高';

  @override
  String get surplus => '黒字';

  @override
  String get deficit => '赤字';

  @override
  String get noBills => '請求書がありません';

  @override
  String get billPaid => '支払済請求書';

  @override
  String get billUnpaid => '未払い請求書';

  @override
  String get markAsPaid => '支払済にする';

  @override
  String get markAsUnpaid => '未払いにする';

  @override
  String get remindMe => 'リマインダー設定';

  @override
  String get reminderSet => 'リマインダーが設定されました';

  @override
  String get noGroups => 'グループがありません';

  @override
  String get joinGroup => 'グループに参加';

  @override
  String get createNewGroup => '新しいグループを作成';

  @override
  String get inviteCode => '招待コード';

  @override
  String get enterInviteCode => '招待コードを入力';

  @override
  String get copyInviteCode => '招待コードをコピー';

  @override
  String get inviteCodeCopied => '招待コードをクリップボードにコピーしました';

  @override
  String get share => '共有';

  @override
  String get shareVia => '共有方法';

  @override
  String get permissions => '権限';

  @override
  String get cameraPermission => 'カメラの権限';

  @override
  String get storagePermission => 'ストレージの権限';

  @override
  String get notificationPermission => '通知の権限';

  @override
  String get grantPermission => '権限を付与';

  @override
  String get permissionDenied => '権限が拒否されました';

  @override
  String get permissionRequired => '権限が必要です';

  @override
  String get about => 'このアプリについて';

  @override
  String get version => 'バージョン';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get rateApp => 'アプリを評価';

  @override
  String get logoutConfirm => '本当にログアウトしますか？';

  @override
  String get unsavedChanges => '保存されていない変更があります。破棄しますか？';

  @override
  String get discard => '破棄';

  @override
  String get keepEditing => '編集を続ける';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get tryAgain => '再試行';

  @override
  String get networkError => 'ネットワークエラー。接続を確認してください。';

  @override
  String get serverError => 'サーバーエラー。後でもう一度お試しください。';

  @override
  String get unknownError => '不明なエラーが発生しました';

  @override
  String get unauthorized => '認証が必要です。再度ログインしてください。';

  @override
  String get forbidden => 'アクセスが拒否されました';

  @override
  String get notFound => '見つかりません';

  @override
  String get tooManyRequests => 'リクエストが多すぎます。しばらくお待ちください。';

  @override
  String get maintenance => 'メンテナンス中です。後でもう一度お試しください。';

  @override
  String get guestMode => 'ゲストモード';

  @override
  String get dataStoredLocally => 'データはこのデバイスにのみ保存されています';

  @override
  String get loginBenefits => 'ログインのメリット';

  @override
  String get syncDataMultipleDevices => '複数デバイスでデータを同期';

  @override
  String get cloudBackup => 'クラウドバックアップで安心';

  @override
  String get shareWithFamily => '家族・パートナーと家計を共有';

  @override
  String get aiUsageManagement => 'AI使用量の管理';

  @override
  String get loginOrRegister => 'ログイン / 新規登録';

  @override
  String get localData => 'ローカルデータ';

  @override
  String get recordCount => '記録件数';

  @override
  String get cloudSync => 'クラウド同期';

  @override
  String get notSet => '未設定';

  @override
  String get myPage => 'マイページ';

  @override
  String get statistics => '統計';

  @override
  String get accountSettings => 'アカウント';

  @override
  String get systemSettings => 'システム';

  @override
  String get aboutVee => 'Veeについて';

  @override
  String get seeMore => 'もっと見る';

  @override
  String get loadMore => 'もっと見る';

  @override
  String get loadMoreData => 'データを読み込む';

  @override
  String get cancelDelete => 'キャンセル';

  @override
  String get deleting => '削除';

  @override
  String get recordCompleted => '記帳が完了しました！';

  @override
  String get categoryLoading => 'カテゴリーを読み込み中...';

  @override
  String categoryLoadError(String error) {
    return 'エラー: $error';
  }

  @override
  String get private => 'プライベート';

  @override
  String get product => '商品';

  @override
  String get discount => '割引';

  @override
  String get tax => '税金';

  @override
  String get retake => '再撮影';

  @override
  String get chooseAgain => '選び直す';

  @override
  String get addDetail => '明細を追加';

  @override
  String get cancelConfirm => 'キャンセル';

  @override
  String get confirmConfirm => '確認';

  @override
  String get layoutUpdated => '配置が更新されました';

  @override
  String updateFailed(String error) {
    return '更新に失敗しました: $error';
  }

  @override
  String get permissionUpdated => '権限が更新され、リアルタイムでユーザーデバイスにプッシュされました';

  @override
  String operationFailed(String error) {
    return '操作に失敗しました: $error';
  }

  @override
  String get changePasswordTitle => 'パスワード変更';

  @override
  String get editProfileTitle => 'プロフィール編集';

  @override
  String get createAccountTitle => 'アカウント作成';

  @override
  String get verifyEmailTitle => 'メール確認';

  @override
  String get removeThis => 'これを削除';

  @override
  String get cannotUndo => 'この操作は元に戻せません。';

  @override
  String get selectMonthYear => '月/年を選択';

  @override
  String get month => '月';

  @override
  String get year => '年';

  @override
  String monthReset(String date) {
    return '$dateにリセット';
  }

  @override
  String used(int count) {
    return '$count回使用済み';
  }

  @override
  String totalQuota(int count) {
    return '合計$count回/月';
  }

  @override
  String get aiUsageQuota => 'AI使用クォータ';

  @override
  String get unlimited => '無制限';

  @override
  String get telegramBind => 'Telegram連携';

  @override
  String get bound => '連携済み';

  @override
  String get unbound => '未連携';

  @override
  String boundWithTelegram(String id) {
    return 'Telegram #$idと紐付け済み';
  }

  @override
  String get quotaSharedAfterBind => '連携後、BotとAppでAI使用量を共有し、一括管理できます';

  @override
  String get bindTelegram => 'Telegramを連携';

  @override
  String get bindTelegramDesc => '連携するとBotとAppでAI使用量を共有できます';

  @override
  String get verificationCode => '確認コード';

  @override
  String get validFor10Minutes => '10分間有効';

  @override
  String sendBindCommand(String code) {
    return 'Telegram Botに移動して送信：\n/bind $code';
  }

  @override
  String get refreshCode => '確認コードを再発行';

  @override
  String get applyBindCode => '連携コードを取得';

  @override
  String get unbind => '連携解除';

  @override
  String get telegramConnection => 'Telegram接続';

  @override
  String get detail => '詳細';

  @override
  String get receiptImages => 'レシート画像';

  @override
  String itemsCount(int count) {
    return '明細 ($count件)';
  }

  @override
  String get uncategorized => '未分類';

  @override
  String fromSource(String source) {
    return '$sourceから記録';
  }

  @override
  String get merchant => '店舗';

  @override
  String get notEntered => '未入力';

  @override
  String get unknown => '不明';

  @override
  String get itemsTotal => '明細合計';

  @override
  String totalRecords(int count) {
    return '$count件の記録';
  }

  @override
  String get noRecords => '記録がありません';

  @override
  String get tryDifferentKeyword => '別のキーワードをお試しください';

  @override
  String get adminConsole => '管理コンソール';

  @override
  String get dataDashboard => 'データダッシュボード';

  @override
  String get systemConfig => 'システム設定';

  @override
  String get userManagement => 'ユーザー管理';

  @override
  String get userOverview => 'ユーザー概要';

  @override
  String get totalUsers => '総ユーザー数';

  @override
  String get activeUsers => 'アクティブユーザー';

  @override
  String get adminCount => '管理者数';

  @override
  String get wsOnline => 'WSオンライン';

  @override
  String get billOverview => '請求書概要';

  @override
  String get totalBills => '請求書総数';

  @override
  String get billsThisMonth => '今月の請求書';

  @override
  String get aiUsageThisMonth => '今月のAI使用量';

  @override
  String aiUsageCountTimes(num count) {
    return '$count回';
  }

  @override
  String get wsConnections => 'WS接続数';

  @override
  String get configValue => '設定値';

  @override
  String get empty => '（空）';

  @override
  String get searchEmailUsername => 'メール/ユーザー名/ニックネームで検索';

  @override
  String get all => 'すべて';

  @override
  String get banned => 'BAN済み';

  @override
  String get configPermission => '権限設定';

  @override
  String get botText => 'Botテキスト';

  @override
  String get botReceipt => 'Bot画像';

  @override
  String get botVoice => 'Bot音声';

  @override
  String get botDownload => 'Botダウンロード';

  @override
  String get appOcr => 'App OCR';

  @override
  String get appExport => 'Appエクスポート';

  @override
  String get appUpload => 'Appアップロード';

  @override
  String get botTextLabel => 'Botテキスト記帳';

  @override
  String get botReceiptLabel => 'Bot画像認識';

  @override
  String get botVoiceLabel => 'Bot音声記帳';

  @override
  String get botDownloadLabel => 'Botダウンロード機能';

  @override
  String get appOcrLabel => 'App OCR認識';

  @override
  String get appExportLabel => 'Appデータエクスポート';

  @override
  String get appUploadLabel => 'App画像アップロード';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String savePermission(int count) {
    return '権限を保存（$count項目）';
  }

  @override
  String registrationIp(String ip) {
    return '登録IP: $ip';
  }

  @override
  String lastIp(String ip) {
    return '最終IP: $ip';
  }

  @override
  String get noPermission => '権限がありません';

  @override
  String get itemsLabel => '項目';

  @override
  String get productName => '商品名';

  @override
  String get quantity => '数量';

  @override
  String get enterAmount => '金額を入力';

  @override
  String get invalidAmount => '無効な金額';

  @override
  String get amountGreaterThanZero => '0より大きい金額を入力';

  @override
  String get calculatedFromTotal => '明細合計から自動計算';

  @override
  String get enterProductName => '商品名を入力';

  @override
  String invalidAmountForItem(int num) {
    return '明細 $num の金額が無効です';
  }

  @override
  String get additionalInfo => '追加情報...';

  @override
  String get notEnteredYet => '（未入力）';

  @override
  String records(int count) {
    return '$count件';
  }

  @override
  String get expenseTotal => '支出合計';

  @override
  String get smartBillAssistant => 'スマート帳簿アシスタント';

  @override
  String get usernameOrEmail => 'ユーザー名またはメール';

  @override
  String get enterUsernameOrEmail => 'ユーザー名またはメールを入力してください';

  @override
  String get enterPassword => 'パスワードを入力してください';

  @override
  String get defaultCategory => 'その他';

  @override
  String imageUploadFailed(String error) {
    return '画像アップロード失敗：$error';
  }

  @override
  String monthDayFormat(int month, int day) {
    return '$month/$day';
  }

  @override
  String quotaResetsOn(String date) {
    return '$dateリセット';
  }

  @override
  String yearMonthFormat(int year, int month) {
    return '$year年$month月';
  }

  @override
  String monthDayJapaneseFormat(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get enterEmail => 'メールアドレスを入力';

  @override
  String get sendFailed => '送信に失敗しました';

  @override
  String get enter6DigitCode => '6桁の確認コードを入力';

  @override
  String get passwordMinLength => 'パスワードは6文字以上必要です';

  @override
  String get verificationFailed => '確認に失敗しました';

  @override
  String get enterRegisteredEmail => '登録メールアドレスを入力';

  @override
  String get willSendResetCode => 'パスワードリセットコードが送信されます';

  @override
  String get sendVerificationCode => '確認コードを送信';

  @override
  String get setNewPassword => '新しいパスワードを設定';

  @override
  String verificationSentTo(String email) {
    return '確認コードを $email に送信しました';
  }

  @override
  String get sixDigitCode => '6桁コード';

  @override
  String get confirmReset => 'リセットを確認';

  @override
  String resendCodeWithCountdown(int seconds) {
    return '$seconds秒後に再送信';
  }

  @override
  String get resendCode => '再送信';

  @override
  String get registerFailed => '登録に失敗しました';

  @override
  String get usernameFormat => 'ユーザー名形式';

  @override
  String get usernameMinLength => 'ユーザー名は3文字以上必要です';

  @override
  String get usernameInvalid => '無効なユーザー名';

  @override
  String get enterValidEmail => '有効なメールアドレスを入力してください';

  @override
  String get passwordNeedsNumber => 'パスワードには数字が必要です';

  @override
  String get passwordNeedsLetter => 'パスワードには文字が必要です';

  @override
  String get registerAgree => '利用規約に同意します';

  @override
  String get checkVerificationCode => '確認コードを確認';

  @override
  String get verifyAndActivate => '確認して有効化';

  @override
  String get didNotReceiveResend => '届かない？再送信';

  @override
  String get changePasswordFailed => 'パスワード変更に失敗しました';

  @override
  String get nicknameRequired => 'ニックネームは必須です';

  @override
  String get saveFailed => '保存に失敗しました';

  @override
  String get usernameEmailCannotChange => 'ユーザー名とメールアドレスは変更できません';

  @override
  String get contactAdmin => '管理者にお問い合わせください';

  @override
  String get noAiPermission => 'AI認識の権限がありません';

  @override
  String get contactAdminForOcr => '管理者に連絡して「App OCR」機能を有効にしてください';

  @override
  String get noUploadPermission => 'レシート画像をアップロードする権限がありません';

  @override
  String get myLedger => 'マイ帳簿';

  @override
  String get payee => '支払先';
}
