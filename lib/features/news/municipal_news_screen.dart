import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/municipal_news_list.dart';

class MunicipalNewsScreen extends StatelessWidget {
  const MunicipalNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FD),
        body: Column(
          children: [
            _buildHeader(context),
            const Expanded(
              child: MunicipalNewsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5BC6), Color(0xFF0A2A66)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'BELEDİYE HABERLERİ',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 48, top: 2),
                child: Text(
                  'Gebze Belediyesi ile ilgili en güncel haberler ve duyurular.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
