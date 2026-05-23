import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. Sukses Import Supabase
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/buttons.dart';
import 'main_shell.dart';
import '../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl = TextEditingController(text: '');
  bool _obscure = true;
  bool _isLoading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
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

  // 2. FUNGSI LOGIN SUDAH TERHUBUNG KE SUPABASE BACKEND
  Future<void> _login() async {
    // Validasi input sederhana agar hemat kuota API
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Langkah A: Coba login menggunakan Email & Password ke Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // Langkah B: Ambil data role ('owner' / 'kasir') dari tabel profiles kamu
        final userData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        final String role = userData['role'] ?? 'kasir';

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Notifikasi Berhasil Berdasarkan Role
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selamat Datang! Masuk sebagai ${role.toUpperCase()}',
            ),
          ),
        );

        // 🔴 Langkah C: Pindahkan user ke halaman utama (MainShell) dengan membawa parameter role
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, a1, a2) =>
                MainShell(role: role), // ◄ Diisi di sini
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } on AuthException catch (error) {
      // Tangani jika salah email/password dari sistem Supabase
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      // Tangani error umum seperti tidak ada internet
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan jaringan atau sistem.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fullscreen background image centered
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/loginlogo.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.srcOver,
                ),
              ),
            ),
          ),

          // 2. Translucent primary color wash overlay
          Container(color: AppColors.primary.withOpacity(0.12)),

          // 3. Center Login Card with Responsive LayoutBuilder & Glass Container
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;

                  // Highly fluid responsive card width:
                  // - On mobile (< 600px): takes screenWidth - 48 (24px margins on each side)
                  // - On tablet (< 960px): dynamically scales between 440px and 560px
                  // - On desktop (>= 960px): elegant 480px width
                  double cardWidth;
                  if (screenWidth < 600) {
                    cardWidth = screenWidth - 48.0;
                  } else if (screenWidth < 960) {
                    cardWidth = (screenWidth * 0.6).clamp(440.0, 560.0);
                  } else {
                    cardWidth = 480.0;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Center(
                      child: GlassContainer(
                        width: cardWidth,
                        borderRadius: 24,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 40,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tanjosu Logo Emblem
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/logotanjosu.jpeg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tanjosu',
                              style: GoogleFonts.manrope(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Masukkan kredensial Anda untuk melanjutkan',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 36),

                            // Form Inputs
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.bodyMd,
                              decoration: const InputDecoration(
                                hintText: 'nama@tanjosu.id',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Password',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: AppTextStyles.bodyMd,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
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
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            PrimaryButton(
                              label: 'Masuk',
                              icon: Icons.arrow_forward_rounded,
                              isLoading: _isLoading,
                              onPressed: _login,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
