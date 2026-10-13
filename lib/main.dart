import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/configure_providers.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = await ConfigureProviders.createDependencyTree();

  runApp(SuperSquadApp(data: data));
}

class SuperSquadApp extends StatelessWidget {
  final ConfigureProviders data;

  const SuperSquadApp({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: data.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Super Squad',
        theme: AppTheme.dark,
        home: const HomePage(),
      ),
    );
  }
}
