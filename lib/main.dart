import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/json_home_page.dart';
import 'domain/json_formatter.dart';
import 'domain/search_manager.dart';

void main() {
  runApp(const MyJsonApp());
}

class MyJsonApp extends StatelessWidget {
  const MyJsonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JsonFormatter()),
        ChangeNotifierProvider(create: (_) => SearchManager()),
      ],
      child: MaterialApp(locale: Locale('en_in'),
        title: 'Grafna JSON Formatter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, brightness: Brightness.light),
          fontFamily: 'SF Pro Display',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, brightness: Brightness.dark),
          fontFamily: 'SF Pro Display',
        ),
        home: const JsonHomePage(),
      ),
    );
  }
}
