import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/buttons.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'kasir@tanjosu.id');
  final _passCtrl = TextEditingController(text: '••••••••');
  bool _obscure = true;
  bool _isLoading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          
          Widget leftPanel = Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D4A00),
                  Color(0xFF446900),
                  Color(0xFF74A12E),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: EdgeInsets.all(isWide ? 64 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/logotanjosu.jpeg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'tanjosu',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (isWide) const Spacer() else const SizedBox(height: 32),
                    // Decorative emojis
                    const Text('🍵', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 24),
                    Text(
                      'Selamat Datang\ndi Tanjosu POS',
                      style: AppTextStyles.displayLg.copyWith(
                        color: Colors.white,
                        height: 1.15,
                        fontSize: isWide ? null : 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sistem kasir premium untuk pengalaman\nservis yang lebih cepat dan elegan.',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: Colors.white.withOpacity(0.75),
                        height: 1.6,
                      ),
                    ),
                    if (isWide) const Spacer() else const SizedBox(height: 32),
                    // Feature chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['☕ Multi-Menu', '📊 Laporan Real-time', '🧾 Cetak Struk']
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Text(
                                  f,
                                  style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );

          Widget rightPanel = Container(
            color: AppColors.background,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 48 : 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Masuk ke Akun', style: AppTextStyles.headlineMd),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan kredensial Anda untuk melanjutkan',
                          style: AppTextStyles.bodySm,
                        ),
                        const SizedBox(height: 40),

                        // Email
                        Text('Email', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.bodyMd,
                          decoration: const InputDecoration(
                            hintText: 'nama@tanjosu.id',
                            prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password
                        Text('Password', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: AppTextStyles.bodyMd,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Lupa Password?',
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Masuk',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isLoading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('atau', style: AppTextStyles.labelSm),
                            ),
                            Expanded(child: Divider(color: AppColors.outlineVariant)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SecondaryButton(
                          label: 'Masuk sebagai Demo',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _login,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: leftPanel),
                Expanded(flex: 4, child: rightPanel),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      leftPanel,
                      Expanded(child: rightPanel),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
