import 'package:flutter/material.dart';

import '../../../ui/theme.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarif rejalari',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Do\'konlar uchun oylik obuna tarif rejalari',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;
            final cards = [
              _PlanCard(
                name: 'START',
                price: '100 000',
                color: const Color(0xFF3B82F6),
                featured: false,
                features: const [
                  'Mahsulotlar: 500 tagacha',
                  'Buyurtmalar: cheksiz',
                  'Qo\'llab-quvvatlash: Standart',
                  'Saqlash: 2 GB',
                  'Mijoz xabarnomalari',
                  'Asosiy analitika',
                ],
              ),
              _PlanCard(
                name: 'BUSINESS',
                price: '300 000',
                color: const Color(0xFF8B5CF6),
                featured: true,
                features: const [
                  'Mahsulotlar: 3000 tagacha',
                  'Buyurtmalar: cheksiz',
                  'Qo\'llab-quvvatlash: Tezkor',
                  'Saqlash: 10 GB',
                  'Marketing vositalari',
                  'To\'liq analitika',
                  'Excel eksport',
                ],
              ),
              _PlanCard(
                name: 'PREMIUM',
                price: '700 000',
                color: const Color(0xFF10B981),
                featured: false,
                features: const [
                  'Mahsulotlar: cheksiz',
                  'Buyurtmalar: cheksiz',
                  'Qo\'llab-quvvatlash: 24/7',
                  'Saqlash: 100 GB',
                  'Maxsus brending',
                  'API kirish',
                  'Maxsus akkaunt menejer',
                  'SLA 99.9%',
                ],
              ),
            ];

            if (isMobile) {
              return Column(
                children: cards.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: c,
                )).toList(),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards.expand((c) sync* {
                yield Expanded(child: c);
                if (c != cards.last) yield const SizedBox(width: 16);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.color,
    required this.featured,
    required this.features,
  });

  final String name;
  final String price;
  final Color color;
  final bool featured;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: featured ? color : AppColors.border,
          width: featured ? 2 : 1,
        ),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('OMMABOP',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          if (featured) const SizedBox(height: 12),
          Text(name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text("so'm / oy",
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: color, size: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name tarifini saqlash uchun do\'konni tanlang')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: featured ? color : Colors.white,
                foregroundColor: featured ? Colors.white : color,
                side: BorderSide(color: color, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: featured ? 0 : 0,
              ),
              child: Text('Tanlash',
                  style: TextStyle(fontWeight: FontWeight.w800, color: featured ? Colors.white : color)),
            ),
          ),
        ],
      ),
    );
  }
}
