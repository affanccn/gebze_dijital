import 'package:flutter/material.dart';

import 'widgets/municipal_news_list.dart';

class MunicipalNewsScreen extends StatelessWidget {
  const MunicipalNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gebze Haberleri')),
      body: MunicipalNewsList(),
    );
  }
}
