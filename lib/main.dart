import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:joy_a_more_test/pages/admin_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Joy-a-More Admin Portal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AdminHomePage(),
    );
  }
}
