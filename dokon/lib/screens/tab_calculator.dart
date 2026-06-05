import 'package:flutter/material.dart';
import '../theme.dart';
import '../util.dart';

class _CalcProd {
  final String key, name, unit, asset;
  final double unitArea;
  final IconData icon;
  const _CalcProd(this.key, this.name, this.unit, this.unitArea, this.icon, this.asset);
}

class _Room {
  final String name;
  final double len, wid;
  _Room(this.name, this.len, this.wid);
  double get area => double.parse((len * wid).toStringAsFixed(2));
}

class CalculatorTab extends StatefulWidget {
  const CalculatorTab({super.key});
  @override
  State<CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<CalculatorTab> {
  static const prods = [
    _CalcProd('penoplex', 'Penoplex (1200×600 mm)', 'dona', 0.72, Icons.view_in_ar, 'assets/calc/penoplex.jpg'),
    _CalcProd('gidro', 'Gidro plyonka', 'm', 1, Icons.water_drop, 'assets/calc/gidro.jpg'),
    _CalcProd('falga', 'Falga', 'm', 1, Icons.receipt_long, 'assets/calc/falga.jpg'),
  ];
  int _sel = 0;
  final _name = TextEditingController();
  final _len = TextEditingController();
  final _wid = TextEditingController();
  final List<_Room> _rooms = [];
  bool _calculated = false;

  _CalcProd get cp => prods[_sel];

  double _qtyFor(double area) => cp.key == 'penoplex' ? (area / cp.unitArea).ceil().toDouble() : area;

  void _addRoom() {
    final l = double.tryParse(_len.text.replaceAll(',', '.'));
    final w = double.tryParse(_wid.text.replaceAll(',', '.'));
    if (l == null || w == null || l <= 0 || w <= 0) {
      notify(context, "Uzunlik va kenglikni to'g'ri kiriting", type: 'error');
      return;
    }
    setState(() {
      _rooms.add(_Room(_name.text.trim().isEmpty ? 'Xona' : _name.text.trim(), l, w));
      _calculated = false;
      _name.clear();
      _len.clear();
      _wid.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalArea = _rooms.fold(0.0, (s, r) => s + r.area);
    final total = cp.key == 'penoplex' ? (totalArea / cp.unitArea).ceil().toDouble() : double.parse(totalArea.toStringAsFixed(2));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Material Hisoblagich', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text("Xonalar bo'yicha kerakli material miqdorini aniqlang",
            style: TextStyle(color: AppColors.grayLight, fontSize: 12.5)),
        const SizedBox(height: 16),
        // material tanlash — rasmli kartalar
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Materialni tanlang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(prods.length, (i) {
            final active = i == _sel;
            final cp = prods[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < prods.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _sel = i;
                    _calculated = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary.withValues(alpha: 0.10) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: active ? AppColors.primary : Theme.of(context).dividerColor, width: active ? 2 : 1.5),
                    ),
                    child: Column(children: [
                      Stack(children: [
                        _matImage(cp),
                        if (active)
                          const Positioned(
                            right: 2,
                            top: 2,
                            child: CircleAvatar(
                                radius: 9,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.check, size: 12, color: Colors.white)),
                          ),
                      ]),
                      const SizedBox(height: 8),
                      Text(_shortName(cp),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12, height: 1.1,
                              color: active ? AppColors.primary : null)),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        // add room box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('Yangi xona qo\'shish', style: TextStyle(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Xona nomi', hintText: 'Masalan: Hojatxona', isDense: true)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _len, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Uzunlik (m)', hintText: '3.5', isDense: true))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _wid, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Kenglik (m)', hintText: '2.5', isDense: true))),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _addRoom, icon: const Icon(Icons.add, size: 18), label: const Text('Qo\'shish'))),
          ]),
        ),
        const SizedBox(height: 16),
        if (_rooms.isNotEmpty) ...[
          Row(children: [
            const Icon(Icons.door_front_door_outlined, size: 16),
            const SizedBox(width: 6),
            const Text('Xonalar', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
                onPressed: () => setState(() { _rooms.clear(); _calculated = false; }),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Tozalash')),
          ]),
          ..._rooms.asMap().entries.map((e) => _roomTile(e.key, e.value)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () => setState(() => _calculated = true),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Hisoblash'),
            ),
          ),
          const SizedBox(height: 16),
          if (_calculated) _resultBox(total),
        ],
      ],
    );
  }

  String _shortName(_CalcProd cp) {
    switch (cp.key) {
      case 'penoplex':
        return 'Penoplex';
      case 'gidro':
        return 'Gidro plyonka';
      case 'falga':
        return 'Falga';
    }
    return cp.name;
  }

  // Material rasmi (assets/calc/...). Rasm bo'lmasa, ikon ko'rsatiladi.
  Widget _matImage(_CalcProd cp) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        cp.asset,
        height: 70,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cp.icon, color: AppColors.primary, size: 30),
        ),
      ),
    );
  }

  Widget _roomTile(int i, _Room r) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text('${r.len}m × ${r.wid}m = ${r.area} m²', style: TextStyle(color: AppColors.grayLight, fontSize: 12)),
          ]),
        ),
        Text('${_qtyFor(r.area)} ${cp.unit}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: () => setState(() { _rooms.removeAt(i); _calculated = false; }),
          icon: const Icon(Icons.close, size: 18, color: AppColors.grayLight),
        ),
      ]),
    );
  }

  Widget _resultBox(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        Text('${total % 1 == 0 ? total.toInt() : total}',
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, height: 1)),
        Text(cp.unit, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15)),
        const SizedBox(height: 4),
        Text(cp.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600)),
        const Divider(color: Colors.white24, height: 26),
        ..._rooms.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${r.name} (${r.area} m²)', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5)),
                Text('${_qtyFor(r.area)} ${cp.unit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ]),
            )),
      ]),
    );
  }
}
