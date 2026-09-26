import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/auth_models.dart';
import 'sign_up_screen.dart';
import '../home/home_screen.dart';
import '../../features/reservations/screens/staff_dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _emailHasError = false;
  bool _passwordHasError = false;
  String _emailErrorText = 'Please enter a valid email address.';
  String _passwordErrorText = 'Incorrect password. Please try again.';

  // Toast state
  _ToastType? _toastType;
  String _toastTitle = '';
  String _toastBody = '';
  bool _showToast = false;

  late AnimationController _toastController;
  late AnimationController _pulseController;
  late AnimationController _btnController;
  late Animation<double> _toastAnim;

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _toastAnim = CurvedAnimation(
      parent: _toastController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _toastController.dispose();
    _pulseController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  void _showToastMessage(_ToastType type, String title, String body) {
    setState(() {
      _toastType = type;
      _toastTitle = title;
      _toastBody = body;
      _showToast = true;
    });
    _toastController.forward(from: 0);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _toastController.reverse().then((_) {
          if (mounted) setState(() => _showToast = false);
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool hasError = false;

    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        _emailHasError = true;
        _emailErrorText = 'Please enter a valid email address.';
      });
      hasError = true;
    } else {
      setState(() => _emailHasError = false);
    }

    if (password.isEmpty) {
      setState(() {
        _passwordHasError = true;
        _passwordErrorText = 'Password cannot be empty.';
      });
      hasError = true;
    } else if (password.length < 6) {
      setState(() {
        _passwordHasError = true;
        _passwordErrorText = 'Password must be at least 6 characters.';
      });
      hasError = true;
    } else {
      setState(() => _passwordHasError = false);
    }

    if (hasError) return;

    // Animate button press
    await _btnController.forward();
    await _btnController.reverse();

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.login(
        email: email,
        password: password,
      );
      if (!mounted) return;
      // ✅ Success — navigate to role-based dashboard
      _showToastMessage(
        _ToastType.success,
        'Authenticated Successfully',
        'Welcome back, ${AuthService.instance.currentUser?.fullName ?? ''}!',
      );
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      final auth = AuthService.instance;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => auth.isStaff ? const StaffDashboardScreen() : const HomeScreen(),
        ),
        (route) => false, // Clear the whole stack
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // Map error to the right field
      if (e.statusCode == 401) {
        setState(() {
          _passwordHasError = true;
          _passwordErrorText = e.userMessage;
        });
      } else {
        _showToastMessage(_ToastType.error, 'Sign In Failed', e.userMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showToastMessage(
        _ToastType.error,
        'Connection Error',
        'Cannot reach the server. Is the backend running?',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final auth = AuthService.instance;
      await auth.loginWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => auth.isStaff ? const StaffDashboardScreen() : const HomeScreen(),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToastMessage(_ToastType.error, 'Sign In Failed', e.userMessage);
    } catch (e) {
      if (!mounted) return;
      _showToastMessage(_ToastType.error, 'Google Sign-in Error', 'Could not complete Google Sign-in.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillDemo() {
    _emailController.text = 'driver@chargesync.network';
    _passwordController.text = 'QuantumDrive2025!';
    setState(() {
      _emailHasError = false;
      _passwordHasError = false;
    });
    _showToastMessage(
      _ToastType.info,
      'Sample Credentials Loaded',
      'Ready to initiate authenticated charging link.',
    );
  }

  void _triggerErrors() {
    _emailController.text = 'invalid.email@node';
    _passwordController.text = '123';
    setState(() {
      _emailHasError = true;
      _emailErrorText = 'Please enter a valid email address.';
      _passwordHasError = true;
      _passwordErrorText = 'Incorrect password. Please try again.';
    });
  }

  void _reset() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _emailHasError = false;
      _passwordHasError = false;
      _showToast = false;
      _isLoading = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              top: topPad,
              bottom: bottomPad + 24,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Branding
                      _buildBranding(),
                      const SizedBox(height: 28),

                      // Toast
                      if (_showToast)
                        FadeTransition(
                          opacity: _toastAnim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.3),
                              end: Offset.zero,
                            ).animate(_toastAnim),
                            child: _buildToast(),
                          ),
                        ),
                      if (_showToast) const SizedBox(height: 16),

                      // Form
                      _buildForm(),
                      const SizedBox(height: 24),

                      // Divider OR
                      _buildDivider(),
                      const SizedBox(height: 20),

                      // Google button
                      _buildGoogleButton(),
                      const SizedBox(height: 24),

                      // Register link
                      _buildRegisterRow(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Status bar ───────────────────────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            '09:41',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              letterSpacing: 0.06,
            ),
          ),
          Row(
            children: const [
              Icon(Icons.signal_cellular_alt_rounded,
                  size: 16, color: AppColors.onSurfaceVariant),
              SizedBox(width: 4),
              Icon(Icons.wifi_rounded,
                  size: 16, color: AppColors.onSurfaceVariant),
              SizedBox(width: 4),
              Icon(Icons.battery_charging_full,
                  size: 18, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  // ── Branding ─────────────────────────────────────────────────────────────────
  Widget _buildBranding() {
    return Column(
      children: [
        // Logo container with glow
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // App name + EV badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ChargeSync',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                letterSpacing: -0.005,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'EV',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.06,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
            letterSpacing: -0.01,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue your charging journey\nand telemetry sync.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Toast ────────────────────────────────────────────────────────────────────
  Widget _buildToast() {
    Color bgColor;
    Color textColor;
    IconData icon;
    switch (_toastType) {
      case _ToastType.success:
        bgColor = AppColors.secondaryContainer.withValues(alpha: 0.2);
        textColor = AppColors.primary;
        icon = Icons.check_circle_rounded;
        break;
      case _ToastType.info:
        bgColor = AppColors.tertiaryContainer.withValues(alpha: 0.2);
        textColor = AppColors.tertiary;
        icon = Icons.info_rounded;
        break;
      default:
        bgColor = AppColors.errorContainer.withValues(alpha: 0.3);
        textColor = AppColors.error;
        icon = Icons.warning_rounded;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _toastTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _toastBody,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Form ─────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          _buildLabel('Email address', 'Primary account'),
          const SizedBox(height: 6),
          _buildEmailField(),
          if (_emailHasError) ...[
            const SizedBox(height: 6),
            _buildFieldError(_emailErrorText),
          ],
          const SizedBox(height: 16),

          // Password field
          _buildLabel('Password', null),
          const SizedBox(height: 6),
          _buildPasswordField(),
          if (_passwordHasError) ...[
            const SizedBox(height: 6),
            _buildFieldError(_passwordErrorText),
          ],
          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, String? subLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        if (subLabel != null)
          Text(
            subLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        color: _emailHasError
            ? AppColors.errorContainer.withValues(alpha: 0.12)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: _emailHasError
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.mail_rounded,
              size: 20, color: AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              onChanged: (_) {
                if (_emailHasError) setState(() => _emailHasError = false);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter your email address',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.outline,
                ),
                isDense: true,
              ),
            ),
          ),
          if (_emailController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _emailController.clear();
                setState(() => _emailHasError = false);
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.cancel_rounded,
                    size: 18, color: AppColors.outline),
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        color: _passwordHasError
            ? AppColors.errorContainer.withValues(alpha: 0.12)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: _passwordHasError
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.lock_rounded, size: 20, color: AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              onChanged: (_) {
                if (_passwordHasError) setState(() => _passwordHasError = false);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter your password',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.outline,
                ),
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 20,
                color: AppColors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldError(String message) {
    return Row(
      children: [
        const Icon(Icons.error_rounded, size: 15, color: AppColors.error),
        const SizedBox(width: 6),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.97).animate(_btnController),
      child: GestureDetector(
        onTap: _isLoading ? null : _handleSubmit,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? Row(
                    key: const ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Authenticating...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                          letterSpacing: 0.02,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.bolt_rounded,
                          size: 18, color: AppColors.onPrimary),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppColors.surfaceContainerHighest),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.outline,
              letterSpacing: 0.06,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppColors.surfaceContainerHighest),
        ),
      ],
    );
  }

  // ── Google button ────────────────────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google G logo using colored Icon approximation
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Register row ─────────────────────────────────────────────────────────────
  Widget _buildRegisterRow() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: "Don't have an account? ",
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SignUpScreen(),
                  ),
                );
              },
              child: Text(
                'Create account',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Security badge ────────────────────────────────────────────────────────────
  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user_rounded,
            size: 16, color: AppColors.outline),
        const SizedBox(width: 6),
        Text(
          '256-bit encrypted EV fleet authentication',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.outline,
            letterSpacing: 0.06,
          ),
        ),
      ],
    );
  }

  // ── Demo panel ────────────────────────────────────────────────────────────────
  Widget _buildDemoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INTERACTIVE TEST CONTROLS',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.outline,
                  letterSpacing: 0.06,
                ),
              ),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, _) => Opacity(
                      opacity:
                          (1.0 - _pulseController.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live UX Mode',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _DemoBtn(
                  label: 'Empty',
                  color: AppColors.onSurface,
                  onTap: _reset),
              const SizedBox(width: 6),
              _DemoBtn(
                  label: 'Valid Auto',
                  color: AppColors.primary,
                  onTap: _fillDemo),
              const SizedBox(width: 6),
              _DemoBtn(
                  label: 'Trigger Err',
                  color: AppColors.error,
                  onTap: _triggerErrors),
              const SizedBox(width: 6),
              _DemoBtn(
                label: 'Spinner',
                color: AppColors.tertiary,
                onTap: () async {
                  setState(() => _isLoading = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _isLoading = false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Demo button ───────────────────────────────────────────────────────────────
class _DemoBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DemoBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google logo painter ───────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    // Simplified G logo using arcs
    final rect = Rect.fromLTWH(0, 0, w, h);
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Blue top arc
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -90 * (3.14159 / 180), 90 * (3.14159 / 180), false)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green bottom right
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 0, 90 * (3.14159 / 180), false)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow bottom left
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 90 * (3.14159 / 180), 90 * (3.14159 / 180), false)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red top left
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 180 * (3.14159 / 180), 90 * (3.14159 / 180), false)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // White inner circle to create donut
    canvas.drawCircle(center, radius * 0.6, Paint()..color = AppColors.surfaceContainer);

    // Right bar for the G
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - h * 0.1, w * 0.5, h * 0.2),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Toast type enum ───────────────────────────────────────────────────────────
enum _ToastType { success, info, error }
