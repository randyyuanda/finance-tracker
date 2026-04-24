import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppL10n {
  AppL10n._(this._lang);

  factory AppL10n.of(BuildContext ctx) =>
      AppL10n._(ctx.watch<ThemeProvider>().language);

  final String _lang;

  String _t(String en, String id, String zh) {
    if (_lang == 'id') return id;
    if (_lang == 'zh') return zh;
    return en;
  }

  // ── Navigation ─────────────────────────────────────────────────
  String get navDashboard => _t('Dashboard', 'Beranda', '主页');
  String get navTransactions => _t('Transactions', 'Transaksi', '交易');
  String get navReports => _t('Reports', 'Laporan', '报告');
  String get navAccount => _t('Account', 'Akun', '我的');

  // ── Common ──────────────────────────────────────────────────────
  String get save => _t('Save', 'Simpan', '保存');
  String get cancel => _t('Cancel', 'Batal', '取消');
  String get add => _t('Add', 'Tambah', '添加');
  String get edit => _t('Edit', 'Edit', '编辑');
  String get delete => _t('Delete', 'Hapus', '删除');
  String get close => _t('Close', 'Tutup', '关闭');
  String get signOut => _t('Sign Out', 'Keluar', '退出登录');
  String get signOutTitle => _t('Sign out?', 'Keluar dari akun?', '确定退出吗？');
  String get signOutMsg =>
      _t('You will be logged out.', 'Anda akan keluar dari akun.', '您将退出当前账户。');
  String get confirm => _t('Confirm', 'Konfirmasi', '确认');
  String get filter => _t('Filter', 'Filter', '筛选');
  String get all => _t('All', 'Semua', '全部');
  String get income => _t('Income', 'Pendapatan', '收入');
  String get expense => _t('Expense', 'Pengeluaran', '支出');
  String get transfer => _t('Transfer', 'Transfer', '转账');

  // ── Auth ────────────────────────────────────────────────────────
  String get welcomeBack => _t('Welcome back', 'Selamat datang kembali', '欢迎回来');
  String get signInSub => _t('Sign in to your account', 'Masuk ke akun Anda', '登录您的账户');
  String get email => _t('Email', 'Email', '邮箱');
  String get password => _t('Password', 'Kata Sandi', '密码');
  String get signIn => _t('Sign In', 'Masuk', '登录');
  String get noAccount =>
      _t("Don't have an account?", 'Belum punya akun?', '还没有账户？');
  String get createAccount => _t('Create Account', 'Buat Akun', '注册账户');
  String get createAccountTitle => _t('Create account', 'Buat akun', '创建账户');
  String get createAccountSub =>
      _t('Start your financial journey', 'Mulai perjalanan finansial Anda', '开始您的财务之旅');
  String get fullName => _t('Full Name', 'Nama Lengkap', '姓名');
  String get confirmPassword => _t('Confirm Password', 'Konfirmasi Kata Sandi', '确认密码');
  String get hasAccount =>
      _t('Already have an account?', 'Sudah punya akun?', '已有账户？');
  String get loginFailed => _t('Login failed', 'Login gagal', '登录失败');
  String get registerFailed => _t('Register failed', 'Registrasi gagal', '注册失败');

  // ── Dashboard ───────────────────────────────────────────────────
  String get dashboardTitle => _t('Dashboard', 'Beranda', '主页');
  String get totalBalance => _t('Total Balance', 'Total Saldo', '总余额');
  String get financialOverview =>
      _t('Financial Overview', 'Ikhtisar Keuangan', '财务概览');
  String get hi => _t('Hi', 'Hai', '嗨');
  String get netSavings => _t('Net Savings', 'Tabungan Bersih', '净储蓄');
  String get thisMonth => _t('This Month', 'Bulan Ini', '本月');
  String get last7Days => _t('Last 7 Days', '7 Hari Terakhir', '近7天');
  String get recentTransactions =>
      _t('Recent Transactions', 'Transaksi Terbaru', '最近交易');
  String get features => _t('Features', 'Fitur', '功能');

  // ── Transactions ────────────────────────────────────────────────
  String get transactions => _t('Transactions', 'Transaksi', '交易记录');
  String get addTransaction =>
      _t('Add Transaction', 'Tambah Transaksi', '添加交易');
  String get amount => _t('Amount', 'Jumlah', '金额');
  String get category => _t('Category', 'Kategori', '类别');
  String get account => _t('Account', 'Akun', '账户');
  String get note => _t('Note', 'Catatan', '备注');
  String get date => _t('Date', 'Tanggal', '日期');
  String get optional => _t('Optional', 'Opsional', '可选');
  String get noTransactions =>
      _t('No transactions yet', 'Belum ada transaksi', '暂无交易记录');

  // ── Goals ───────────────────────────────────────────────────────
  String get goals => _t('Goals', 'Target', '目标');
  String get addGoal => _t('Add Goal', 'Tambah Target', '添加目标');
  String get goalName => _t('Goal Name', 'Nama Target', '目标名称');
  String get targetAmount => _t('Target Amount', 'Jumlah Target', '目标金额');
  String get currentAmount => _t('Current Amount', 'Jumlah Saat Ini', '当前金额');
  String get deadline => _t('Deadline', 'Batas Waktu', '截止日期');
  String get noGoals => _t('No goals yet', 'Belum ada target', '暂无目标');
  String get completed => _t('Completed', 'Selesai', '已完成');
  String get inProgress => _t('In Progress', 'Dalam Proses', '进行中');

  // ── Reminders ───────────────────────────────────────────────────
  String get reminders => _t('Reminders', 'Pengingat', '提醒');
  String get addReminder =>
      _t('Add Reminder', 'Tambah Pengingat', '添加提醒');
  String get reminderTitle => _t('Title', 'Judul', '标题');
  String get noReminders =>
      _t('No reminders', 'Belum ada pengingat', '暂无提醒');

  // ── Accounts ────────────────────────────────────────────────────
  String get accounts => _t('Accounts', 'Rekening', '账户');
  String get addAccount => _t('Add Account', 'Tambah Rekening', '添加账户');
  String get balance => _t('Balance', 'Saldo', '余额');
  String get accountName => _t('Account Name', 'Nama Rekening', '账户名称');
  String get accountType => _t('Account Type', 'Tipe Rekening', '账户类型');
  String get noAccounts =>
      _t('No accounts yet', 'Belum ada rekening', '暂无账户');

  // ── Recurring ───────────────────────────────────────────────────
  String get recurring =>
      _t('Recurring Transactions', 'Transaksi Berulang', '定期交易');
  String get addRecurring => _t('Add Recurring', 'Tambah Berulang', '添加定期');

  // ── Reports ─────────────────────────────────────────────────────
  String get reports => _t('Reports & Export', 'Laporan & Ekspor', '报告导出');
  String get reportsTitle => _t('Reports', 'Laporan', '财务报告');

  // ── Account tab (More) ──────────────────────────────────────────
  String get accountTab => _t('Account', 'Akun', '我的账户');
  String get goalsReminders =>
      _t('Goals & Reminders', 'Target & Pengingat', '目标和提醒');
  String get finance => _t('Finance', 'Keuangan', '财务');
  String get recurringShort =>
      _t('Recurring Transactions', 'Transaksi Berulang', '定期交易');
  String get reportsExport =>
      _t('Reports & Export', 'Laporan & Ekspor', '报告和导出');
  String get simulasiKredit =>
      _t('Loan Simulators', 'Simulasi Kredit', '贷款模拟');
  String get simulasiKprMenu =>
      _t('Mortgage Simulator (KPR)', 'Simulasi KPR', 'KPR 贷款模拟');
  String get simulasiMotorMenu =>
      _t('Motorcycle Loan', 'Simulasi Kredit Motor', '摩托车贷款模拟');
  String get simulasiMobilMenu =>
      _t('Car Loan', 'Simulasi Kredit Mobil', '汽车贷款模拟');
  String get appSection => _t('App', 'Aplikasi', '应用');
  String get settings => _t('Settings', 'Pengaturan', '设置');

  // ── Settings ────────────────────────────────────────────────────
  String get settingsTitle => _t('Settings', 'Pengaturan', '设置');
  String get profile => _t('Profile', 'Profil', '个人信息');
  String get appearance => _t('Appearance', 'Tampilan', '外观');
  String get theme => _t('Theme', 'Tema', '主题');
  String get language => _t('Language', 'Bahasa', '语言');
  String get tapToChangePhoto =>
      _t('Tap to change photo', 'Ketuk untuk ganti foto', '点击更换头像');
  String get profileUpdated =>
      _t('Profile updated', 'Profil diperbarui', '个人信息已更新');
  String get updateFailed =>
      _t('Failed to update', 'Gagal memperbarui', '更新失败');
  String get takePhoto => _t('Take a photo', 'Ambil foto', '拍照');
  String get chooseGallery =>
      _t('Choose from gallery', 'Pilih dari galeri', '从相册选择');
  String get removePhoto => _t('Remove photo', 'Hapus foto', '删除照片');
  String get nameLabel => _t('Name', 'Nama', '姓名');

  // ── Simulator ───────────────────────────────────────────────────
  String get simKprTitle => _t('Mortgage (KPR)', 'Simulasi KPR', 'KPR 贷款模拟');
  String get simKprSub =>
      _t('Home Ownership Credit', 'Kredit Pemilikan Rumah', '房屋所有权贷款');
  String get simMotorTitle =>
      _t('Motorcycle Loan', 'Kredit Motor', '摩托车贷款模拟');
  String get simMotorSub =>
      _t('Motorcycle Credit', 'Kredit Sepeda Motor', '摩托车分期贷款');
  String get simMobilTitle => _t('Car Loan', 'Kredit Mobil', '汽车贷款模拟');
  String get simMobilSub =>
      _t('Vehicle Credit', 'Kredit Kendaraan Bermotor', '汽车分期贷款');
  String get simLoanParam =>
      _t('Loan Parameters', 'Parameter Pinjaman', '贷款参数');
  String get simResult =>
      _t('Simulation Result', 'Hasil Simulasi', '模拟结果');
  String get simPrice => _t('Property / Item Price', 'Harga Barang', '商品价格');
  String get simDpPct => _t('Down Payment (%)', 'Uang Muka / DP (%)', '首付比例 (%)');
  String get simDpAmount => _t('DP Amount', 'Jumlah DP', '首付金额');
  String get simRate =>
      _t('Annual Interest Rate', 'Suku Bunga Tahunan', '年利率');
  String get simTenor => _t('Loan Tenure', 'Tenor', '贷款期限');
  String get simYears => _t('years', 'tahun', '年');
  String get simMonths => _t('months', 'bulan', '个月');
  String get simMonthly =>
      _t('Monthly Installment', 'Cicilan Per Bulan', '月供');
  String get simFor => _t('for', 'selama', '期限');
  String get simDp => _t('Down Payment (DP)', 'Uang Muka (DP)', '首付金额');
  String get simPrincipal =>
      _t('Loan Principal', 'Pokok Pinjaman', '贷款本金');
  String get simTotal =>
      _t('Total Payment', 'Total Pembayaran', '总还款额');
  String get simInterest => _t('Total Interest', 'Total Bunga', '总利息');
  String get simDisclaimer => _t(
    '* Estimate only. Actual rates may differ by lender.',
    '* Simulasi estimasi. Suku bunga aktual dapat berbeda.',
    '* 以上为估算值，实际利率以金融机构为准。',
  );
}

extension L10nExt on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
