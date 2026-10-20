import 'app/app_config.dart';
import 'app/bootstrap.dart';

Future<void> main() async => await bootstrap(const AppConfig.prod());
