import 'package:flutter/material.dart';

/// Simple app localization without code generation.
///
/// Supports English and Chinese with manual string lookup.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Care Ledger',
      'ledger': 'Ledger',
      'review': 'Review',
      'timeline': 'Timeline',
      'balance': 'Balance',
      'settings': 'Settings',
      'addEntry': 'Add Care Entry',
      'editEntry': 'Edit Entry',
      'description': 'Description',
      'descriptionHint': 'What did you do? (optional)',
      'category': 'Category',
      'credits': 'Credits',
      'date': 'Date',
      'time': 'Time',
      'author': 'Author',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'add': 'Add',
      'edit': 'Edit',
      'approve': 'Approve',
      'reject': 'Reject',
      'requestEdit': 'Request Edit',
      'thisWeek': 'This Week',
      'recentEntries': 'Recent Entries',
      'noEntries': 'No entries yet',
      'noEntriesHint': 'Tap + to add your first care entry',
      'entries': 'Entries',
      'confirmed': 'Confirmed',
      'pending': 'Pending',
      'participants': 'Participants',
      'participantName': 'Participant Name',
      'addParticipant': 'Add Participant',
      'language': 'Language',
      'theme': 'Theme',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'syncStatus': 'Sync Status',
      'localMode': 'Local mode (sync not yet enabled)',
      'localModeDesc': 'All data is stored locally on this device.',
      'ledgerInfo': 'Ledger',
      'title': 'Title',
      'status': 'Status',
      'totalEntries': 'Total entries',
      'appVersion': 'v1.0.0 · MVP',
      'nothingToReview': 'Nothing to review this week',
      'nothingToReviewDesc':
          'All entries have been reviewed. New entries will appear here when they need your attention.',
      'bulkActions': 'Bulk Actions',
      'selected': 'selected',
      'noActiveLedger': 'No active ledger',
      'welcomeTitle': 'Welcome to Care Ledger',
      'welcomeDesc':
          'Create a shared ledger to start tracking caregiving efforts between participants.',
      'createLedger': 'Create Ledger',
      'needsReview': 'needs review',
      'proposeSettlement': 'Propose Settlement',
      'settlements': 'Settlements',
      'balanced': 'Balanced!',
      'net': 'Net',
      'pendingCredits': 'Pending Credits',
      'confirmedCredits': 'confirmed credits',
      'balanceOverview': 'Balance Overview',
      'today': 'Today',
      'allParticipants': 'All participants',
      'day': 'Day',
      'week': 'Week',
      'noEntriesToShow': 'No entries to show',
      'you': 'You',
      'driving': 'Driving',
      'laundry': 'Laundry',
      'childcare': 'Childcare',
      'cooking': 'Cooking',
      'shopping': 'Shopping',
      'planning': 'Planning',
      'emotionalSupport': 'Emotional Support',
      'housework': 'Housework',
      'medical': 'Medical',
      'other': 'Other',
      'appearance': 'Appearance',
      'general': 'General',
      'about': 'About',
    },
    'zh': {
      'appTitle': '照护账本',
      'ledger': '账本',
      'review': '审核',
      'timeline': '时间线',
      'balance': '余额',
      'settings': '设置',
      'addEntry': '添加照护记录',
      'editEntry': '编辑记录',
      'description': '描述',
      'descriptionHint': '你做了什么？（可选）',
      'category': '类别',
      'credits': '积分',
      'date': '日期',
      'time': '时间',
      'author': '记录人',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'add': '添加',
      'edit': '编辑',
      'approve': '批准',
      'reject': '拒绝',
      'requestEdit': '请求修改',
      'thisWeek': '本周',
      'recentEntries': '最近记录',
      'noEntries': '暂无记录',
      'noEntriesHint': '点击 + 添加第一条照护记录',
      'entries': '记录',
      'confirmed': '已确认',
      'pending': '待审核',
      'participants': '参与者',
      'participantName': '参与者姓名',
      'addParticipant': '添加参与者',
      'language': '语言',
      'theme': '主题',
      'themeSystem': '跟随系统',
      'themeLight': '浅色',
      'themeDark': '深色',
      'syncStatus': '同步状态',
      'localMode': '本地模式（同步尚未启用）',
      'localModeDesc': '所有数据存储在本设备上。',
      'ledgerInfo': '账本',
      'title': '标题',
      'status': '状态',
      'totalEntries': '总记录数',
      'appVersion': 'v1.0.0 · MVP',
      'nothingToReview': '本周无需审核',
      'nothingToReviewDesc': '所有记录已审核完毕。新记录需要您关注时会出现在这里。',
      'bulkActions': '批量操作',
      'selected': '已选择',
      'noActiveLedger': '无活动账本',
      'welcomeTitle': '欢迎使用照护账本',
      'welcomeDesc': '创建共享账本，开始追踪参与者之间的照护付出。',
      'createLedger': '创建账本',
      'needsReview': '条待审核',
      'proposeSettlement': '提议结算',
      'settlements': '结算记录',
      'balanced': '已平衡！',
      'net': '净额',
      'pendingCredits': '待确认积分',
      'confirmedCredits': '已确认积分',
      'balanceOverview': '余额概览',
      'today': '今天',
      'allParticipants': '所有参与者',
      'day': '日',
      'week': '周',
      'noEntriesToShow': '暂无记录',
      'you': '我',
      'driving': '接送',
      'laundry': '洗衣',
      'childcare': '育儿',
      'cooking': '做饭',
      'shopping': '购物',
      'planning': '计划',
      'emotionalSupport': '情感支持',
      'housework': '家务',
      'medical': '医疗',
      'other': '其他',
      'appearance': '外观',
      'general': '通用',
      'about': '关于',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
