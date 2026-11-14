import 'dart:async';

// ==========================================
// 1. ABSTRACT CLASS KENDARAAN
// ==========================================

abstract class Kendaraan {
  final String plat;
  final DateTime waktuMasuk;

  Kendaraan({required this.plat, required this.waktuMasuk});

  String get jenis;

  int get tarifPerJam;

  // Menghitung biaya parkir dengan pembulatan ke atas
  // Minimal pembayaran adalah 1 jam.
  int biaya(DateTime keluar) {
    final durasi = keluar.difference(waktuMasuk);
    final jam = (durasi.inSeconds / 3600).ceil();

    final totalJam = jam < 1 ? 1 : jam;

    return totalJam * tarifPerJam;
  }
}

// ==========================================
// 2. CLASS MOTOR, MOBIL, DAN TRUK
// ==========================================

class Motor extends Kendaraan {
  Motor({required super.plat, required super.waktuMasuk});

  @override
  String get jenis => 'Motor';

  @override
  int get tarifPerJam => 6000;
}

class Mobil extends Kendaraan {
  Mobil({required super.plat, required super.waktuMasuk});

  @override
  String get jenis => 'Mobil';

  @override
  int get tarifPerJam => 15000;
}

class Truk extends Kendaraan {
  Truk({required super.plat, required super.waktuMasuk});

  @override
  String get jenis => 'Truk';

  @override
  int get tarifPerJam => 20000;
}

// ==========================================
// 3. MIXIN BERLANGGANAN
// ==========================================

mixin Berlangganan on Kendaraan {
  @override
  int biaya(DateTime keluar) {
    final biayaNormal = super.biaya(keluar);

    // Member mendapatkan diskon 50%
    return (biayaNormal * 0.5).ceil();
  }
}

// Mobil khusus untuk anggota/member
class MobilMember extends Mobil with Berlangganan {
  MobilMember({required super.plat, required super.waktuMasuk});

  @override
  String get jenis => 'Mobil (member)';
}

// ==========================================
// 4. CUSTOM EXCEPTION PARKIR PENUH
// ==========================================

class ParkirPenuh implements Exception {
  final int kapasitas;

  ParkirPenuh(this.kapasitas);

  @override
  String toString() {
    return 'Parkiran penuh (kapasitas $kapasitas)';
  }
}

// ==========================================
// 5. CLASS PARKIRAN
// ==========================================

class Parkiran {
  final int kapasitas;

  // Menyimpan kendaraan yang sedang parkir
  final Map<String, Kendaraan> _kendaraan = {};

  // Menyimpan total pendapatan parkir
  int _pendapatan = 0;

  // StreamController untuk mengirim aktivitas parkir
  final StreamController<String> _controller =
      StreamController<String>.broadcast(sync: true);

  Parkiran({required this.kapasitas});

  // Getter untuk menghitung sisa kapasitas
  int get sisa => kapasitas - _kendaraan.length;

  // Getter untuk melihat total pendapatan
  int get pendapatan => _pendapatan;

  // Stream aktivitas parkir
  Stream<String> get aktivitas => _controller.stream;

  // Proses kendaraan masuk
  Future<void> masuk(Kendaraan kendaraan) async {
    print('Memproses kendaraan masuk...');

    // Simulasi palang parkir terbuka
    await Future.delayed(const Duration(seconds: 1));

    if (_kendaraan.length >= kapasitas) {
      throw ParkirPenuh(kapasitas);
    }

    _kendaraan[kendaraan.plat] = kendaraan;

    _controller.add('MASUK ${kendaraan.jenis} ${kendaraan.plat} (sisa $sisa)');
  }

  // Proses kendaraan keluar
  Future<void> keluar(String plat) async {
    print('Memproses kendaraan keluar...');

    // Simulasi palang parkir terbuka
    await Future.delayed(const Duration(seconds: 1));

    final kendaraan = _kendaraan[plat];

    if (kendaraan == null) {
      throw Exception('Kendaraan tidak ditemukan');
    }

    final biaya = kendaraan.biaya(DateTime.now());

    _kendaraan.remove(plat);
    _pendapatan += biaya;

    _controller.add(
      'KELUAR ${kendaraan.jenis} ${kendaraan.plat} '
      'bayar Rp$biaya',
    );
  }

  // Menutup StreamController
  Future<void> tutup() async {
    await _controller.close();
  }
}

// ==========================================
// 6. FUNGSI MAIN
// ==========================================

Future<void> main() async {
  // Membuat objek parkiran dengan kapasitas 3 kendaraan
  final parkiran = Parkiran(kapasitas: 3);

  // Mendengarkan aktivitas parkir melalui Stream
  parkiran.aktivitas.listen((pesan) {
    print(pesan);
  });

  print('======================================');
  print('       SISTEM PARKIR KAMPUS FMIPA');
  print('======================================');

  // Daftar kendaraan menggunakan konsep polimorfisme
  final daftarKendaraan = <Kendaraan>[
    Motor(plat: 'BK 1234 AB', waktuMasuk: DateTime.now()),
    Mobil(plat: 'BK 88 UN', waktuMasuk: DateTime.now()),
    MobilMember(plat: 'BK 7 MIPA', waktuMasuk: DateTime.now()),
  ];

  // Memproses kendaraan masuk
  print('\n--- PROSES KENDARAAN MASUK ---');

  for (final kendaraan in daftarKendaraan) {
    await parkiran.masuk(kendaraan);
  }

  // Menguji kapasitas parkir yang sudah penuh
  print('\n--- UJI KAPASITAS PARKIR ---');

  try {
    await parkiran.masuk(Truk(plat: 'BK 9999 TR', waktuMasuk: DateTime.now()));
  } on ParkirPenuh catch (e) {
    print('Ditolak: $e');
  }

  // Memproses kendaraan keluar
  print('\n--- PROSES KENDARAAN KELUAR ---');

  for (final kendaraan in daftarKendaraan) {
    await parkiran.keluar(kendaraan.plat);
  }

  // Menampilkan laporan pendapatan
  print('\n======================================');
  print('          LAPORAN PARKIR');
  print('======================================');
  print('Total Pendapatan : Rp${parkiran.pendapatan}');
  print('Sisa Kapasitas   : ${parkiran.sisa}');
  print('======================================');

  // Menutup StreamController
  await parkiran.tutup();
}
