enum ReportPeriod { harian, mingguan, bulanan, tahunan }

class SalesDatum {
  final String label;
  final double amount;
  final int transactions;

  const SalesDatum({
    required this.label,
    required this.amount,
    required this.transactions,
  });
}

class ReportSummary {
  final double totalRevenue;
  final int totalTransactions;
  final int totalItems;
  final double avgOrder;
  final double revenueChange; // % vs periode sebelumnya
  final double transactionChange;

  const ReportSummary({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalItems,
    required this.avgOrder,
    required this.revenueChange,
    required this.transactionChange,
  });
}

class TopProduct {
  final String name;
  final String emoji;
  final int qty;
  final double pct;

  const TopProduct({
    required this.name,
    required this.emoji,
    required this.qty,
    required this.pct,
  });
}

// ── Dummy chart data ──────────────────────────────────────────────

const harianData = [
  SalesDatum(label: 'Senin', amount: 720000, transactions: 28),
  SalesDatum(label: 'Selasa', amount: 610000, transactions: 22),
  SalesDatum(label: 'Rabu', amount: 834000, transactions: 31),
  SalesDatum(label: 'Kamis', amount: 920000, transactions: 35),
  SalesDatum(label: 'Jumat', amount: 1100000, transactions: 42),
  SalesDatum(label: 'Sabtu', amount: 1380000, transactions: 52),
  SalesDatum(label: 'Minggu', amount: 1250000, transactions: 48), // Hari Ini
];

const mingguanData = [
  SalesDatum(label: 'Mg 1', amount: 5600000, transactions: 215),
  SalesDatum(label: 'Mg 2', amount: 6814000, transactions: 258),
  SalesDatum(label: 'Mg 3', amount: 6100000, transactions: 232),
  SalesDatum(label: 'Mg 4', amount: 7200000, transactions: 275),
];

const bulananData = [
  SalesDatum(label: 'Mg 1', amount: 4200000, transactions: 158),
  SalesDatum(label: 'Mg 2', amount: 5100000, transactions: 192),
  SalesDatum(label: 'Mg 3', amount: 4750000, transactions: 178),
  SalesDatum(label: 'Mg 4', amount: 6300000, transactions: 237),
];

const tahunanData = [
  SalesDatum(label: 'Jan', amount: 18500000, transactions: 680),
  SalesDatum(label: 'Feb', amount: 16200000, transactions: 598),
  SalesDatum(label: 'Mar', amount: 19800000, transactions: 735),
  SalesDatum(label: 'Apr', amount: 21300000, transactions: 792),
  SalesDatum(label: 'Mei', amount: 23600000, transactions: 865),
  SalesDatum(label: 'Jun', amount: 22100000, transactions: 818),
  SalesDatum(label: 'Jul', amount: 24500000, transactions: 901),
  SalesDatum(label: 'Agu', amount: 26800000, transactions: 978),
  SalesDatum(label: 'Sep', amount: 25200000, transactions: 924),
  SalesDatum(label: 'Okt', amount: 27900000, transactions: 1023),
  SalesDatum(label: 'Nov', amount: 29300000, transactions: 1072),
  SalesDatum(label: 'Des', amount: 34100000, transactions: 1248),
];

// ── Summary per hari (Senin - Minggu) ──────────────────────────────

const seninSummary = ReportSummary(
  totalRevenue: 720000,
  totalTransactions: 28,
  totalItems: 84,
  avgOrder: 25714,
  revenueChange: -5.2,
  transactionChange: -3.1,
);

const selasaSummary = ReportSummary(
  totalRevenue: 610000,
  totalTransactions: 22,
  totalItems: 66,
  avgOrder: 27727,
  revenueChange: -15.2,
  transactionChange: -21.4,
);

const rabuSummary = ReportSummary(
  totalRevenue: 834000,
  totalTransactions: 31,
  totalItems: 93,
  avgOrder: 26903,
  revenueChange: 36.7,
  transactionChange: 40.9,
);

const kamisSummary = ReportSummary(
  totalRevenue: 920000,
  totalTransactions: 35,
  totalItems: 105,
  avgOrder: 26285,
  revenueChange: 10.3,
  transactionChange: 12.9,
);

const jumatSummary = ReportSummary(
  totalRevenue: 1100000,
  totalTransactions: 42,
  totalItems: 126,
  avgOrder: 26190,
  revenueChange: 19.5,
  transactionChange: 20.0,
);

const sabtuSummary = ReportSummary(
  totalRevenue: 1380000,
  totalTransactions: 52,
  totalItems: 156,
  avgOrder: 26538,
  revenueChange: 25.4,
  transactionChange: 23.8,
);

const mingguSummary = ReportSummary(
  totalRevenue: 1250000,
  totalTransactions: 48,
  totalItems: 144,
  avgOrder: 26041,
  revenueChange: -9.4,
  transactionChange: -7.6,
);

// ── Summary per periode lainnya ───────────────────────────────────

const mingguanSummary = ReportSummary(
  totalRevenue: 25714000,
  totalTransactions: 980,
  totalItems: 2840,
  avgOrder: 26238,
  revenueChange: 11.2,
  transactionChange: 8.7,
);

const bulananSummary = ReportSummary(
  totalRevenue: 20350000,
  totalTransactions: 765,
  totalItems: 2184,
  avgOrder: 26601,
  revenueChange: 15.2,
  transactionChange: 11.8,
);

const tahunanSummary = ReportSummary(
  totalRevenue: 289300000,
  totalTransactions: 10634,
  totalItems: 30421,
  avgOrder: 27207,
  revenueChange: 23.5,
  transactionChange: 18.9,
);

// ── Top products per hari (Senin - Minggu) ─────────────────────────

const topProductsSenin = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 12, pct: 0.75),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 9, pct: 0.56),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 7, pct: 0.43),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 5, pct: 0.31),
  TopProduct(name: 'KHS Strawberry', emoji: '🍓', qty: 4, pct: 0.25),
];

const topProductsSelasa = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 10, pct: 0.71),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 8, pct: 0.57),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 6, pct: 0.43),
  TopProduct(name: 'KHS Strawberry', emoji: '🍓', qty: 4, pct: 0.28),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 3, pct: 0.21),
];

const topProductsRabu = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 15, pct: 0.78),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 12, pct: 0.63),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 10, pct: 0.52),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 8, pct: 0.42),
  TopProduct(name: 'KHS Durian Keju', emoji: '🧀', qty: 5, pct: 0.26),
];

const topProductsKamis = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 18, pct: 0.81),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 14, pct: 0.63),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 11, pct: 0.50),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 9, pct: 0.40),
  TopProduct(name: 'KHS Strawberry', emoji: '🍓', qty: 7, pct: 0.31),
];

const topProductsJumat = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 22, pct: 0.84),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 18, pct: 0.69),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 14, pct: 0.53),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 11, pct: 0.42),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 9, pct: 0.34),
];

const topProductsSabtu = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 28, pct: 0.87),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 22, pct: 0.68),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 18, pct: 0.56),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 14, pct: 0.43),
  TopProduct(name: 'KHS Strawberry', emoji: '🍓', qty: 10, pct: 0.31),
];

const topProductsMinggu = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 25, pct: 0.86),
  TopProduct(name: 'KHS Coklat Crunchy', emoji: '🧇', qty: 20, pct: 0.68),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 16, pct: 0.55),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 12, pct: 0.41),
  TopProduct(name: 'KHS Strawberry', emoji: '🍓', qty: 8, pct: 0.27),
];

// ── Top products per periode lainnya ──────────────────────────────

const topProductsMingguan = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 198, pct: 0.90),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 162, pct: 0.74),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 145, pct: 0.66),
  TopProduct(name: 'KHS Coklat Regal', emoji: '🍪', qty: 112, pct: 0.51),
  TopProduct(name: 'KHS Milo', emoji: '🥤', qty: 98, pct: 0.45),
];

const topProductsBulanan = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 745, pct: 0.92),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 612, pct: 0.75),
  TopProduct(name: 'KHS Strawberry Ice Cream', emoji: '🍨', qty: 534, pct: 0.66),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 421, pct: 0.52),
  TopProduct(name: 'KHS Durian Keju', emoji: '🧀', qty: 387, pct: 0.47),
];

const topProductsTahunan = [
  TopProduct(name: 'KHS Coklat Keju', emoji: '🧀', qty: 8924, pct: 0.95),
  TopProduct(name: 'KHS Green Tea', emoji: '🍵', qty: 7312, pct: 0.78),
  TopProduct(name: 'KHS Alpukat', emoji: '🥑', qty: 6543, pct: 0.70),
  TopProduct(name: 'KHS Milo Coco Krunch', emoji: '🥣', qty: 5128, pct: 0.55),
  TopProduct(name: 'KHS Tiramisu Regal', emoji: '🍪', qty: 4891, pct: 0.52),
];

// ── Helper to get data by period ──────────────────────────────────

List<SalesDatum> getSalesData(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return harianData;
    case ReportPeriod.mingguan: return mingguanData;
    case ReportPeriod.bulanan: return bulananData;
    case ReportPeriod.tahunan: return tahunanData;
  }
}

ReportSummary getSummary(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return mingguSummary; // default ke Minggu (Hari Ini)
    case ReportPeriod.mingguan: return mingguanSummary;
    case ReportPeriod.bulanan: return bulananSummary;
    case ReportPeriod.tahunan: return tahunanSummary;
  }
}

List<TopProduct> getTopProducts(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return topProductsMinggu; // default ke Minggu
    case ReportPeriod.mingguan: return topProductsMingguan;
    case ReportPeriod.bulanan: return topProductsBulanan;
    case ReportPeriod.tahunan: return topProductsTahunan;
  }
}

String getPeriodLabel(ReportPeriod period) {
  switch (period) {
    case ReportPeriod.harian: return 'Minggu';
    case ReportPeriod.mingguan: return 'Bulan Ini';
    case ReportPeriod.bulanan: return 'Kuartal Ini';
    case ReportPeriod.tahunan: return 'Tahun Ini';
  }
}
