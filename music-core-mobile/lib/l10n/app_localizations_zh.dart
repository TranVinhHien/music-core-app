// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get loginTitle => '登录';

  @override
  String get loginSubtitle => '使用以下任一演示账号登录，即可体验应用。';

  @override
  String get demoCredentials => '演示账号';

  @override
  String get emailLabel => '邮箱地址';

  @override
  String get passwordLabel => '密码';

  @override
  String get emailRequired => '请输入邮箱地址';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get loginButton => '登录';

  @override
  String get invalidCredentials => '邮箱或密码不正确，请重新输入';

  @override
  String get storageError => '暂时无法访问本地数据，请稍后重试';

  @override
  String get unexpectedError => '出了点问题，请稍后重试';

  @override
  String get retry => '重试';

  @override
  String get tasksTitle => '任务';

  @override
  String get logout => '退出登录';

  @override
  String get filterAll => '全部';

  @override
  String get filterActive => '未完成';

  @override
  String get filterCompleted => '已完成';

  @override
  String get emptyTasksTitle => '暂无任务';

  @override
  String get emptyTasksMessage => '点击“添加任务”创建第一条任务。';

  @override
  String get addTask => '添加任务';

  @override
  String get editTask => '编辑任务';

  @override
  String get deleteTask => '删除任务';

  @override
  String get taskTitleLabel => '任务标题';

  @override
  String get taskTitleRequired => '请输入任务标题';

  @override
  String get deleteTaskConfirmation => '删除后无法恢复，确定要删除这条任务吗？';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get taskNotFound => '找不到这条任务';

  @override
  String get pageNotFound => '找不到这个页面';
}
