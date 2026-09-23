import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/auth_models.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  // Page controller for multi-step form
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // ── Step 1: Account Info ────────────────────────────────────────────────────
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // ── Step 2: Security ────────────────────────────────────────────────────────
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  // ── Step 3: Vehicle Profile ─────────────────────────────────────────────────
  String _selectedMake = 'Tesla';
  String _selectedModel = 'Model Y';
  String _selectedConnector = 'NACS (Tesla)';
  final _vehicleYearController = TextEditingController(text: '2024');
  final _licensePlateController = TextEditingController();

  // ── Errors ──────────────────────────────────────────────────────────────────
  final Map<String, String?> _errors = {};

  // ── Animation ───────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnim;
  bool _isLoading = false;
  bool _isSuccess = false;

  // ── Options ─────────────────────────────────────────────────────────────────
  final List<String> _carMakes = ['Tesla', 'Rivian', 'BMW', 'Hyundai', 'Kia', 'Audi', 'Ford', 'Chevrolet', 'Porsche', 'Lucid'];
  final Map<String, List<String>> _carModels = {
    'Tesla': ['Model Y', 'Model 3', 'Model S', 'Model X', 'Cybertruck'],
    'Rivian': ['R1T', 'R1S', 'R2'],
    'BMW': ['i4', 'iX', 'i5', 'i7'],
    'Hyundai': ['IONIQ 5', 'IONIQ 6', 'IONIQ 9'],
    'Kia': ['EV6', 'EV9', 'EV3'],
    'Audi': ['e-tron GT', 'Q8 e-tron', 'Q4 e-tron'],
    'Ford': ['Mustang Mach-E', 'F-150 Lightning'],
    'Chevrolet': ['Silverado EV', 'Equinox EV', 'Blazer EV'],
    'Porsche': ['Taycan', 'Macan EV'],
    'Lucid': ['Air Grand Touring', 'Air Pure', 'Gravity'],
  };
  final List<String> _connectors = ['NACS (Tesla)', 'CCS1', 'CCS2', 'CHAdeMO', 'J1772'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1 / _totalSteps)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
    _progressController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleYearController.dispose();
    _licensePlateController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────
  void _nextStep() {
    if (_validateCurrentStep()) {
      final next = _currentStep + 1;
      setState(() => _currentStep = next);
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: (next + 1) / _totalSteps,
      ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
      _progressController.forward(from: 0);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      final prev = _currentStep - 1;
      setState(() => _currentStep = prev);
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: (prev + 1) / _totalSteps,
      ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
      _progressController.forward(from: 0);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Validation ───────────────────────────────────────────────────────────────
  bool _validateCurrentStep() {
    setState(() => _errors.clear());
    bool valid = true;

    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty) {
        _errors['firstName'] = 'First name is required';
        valid = false;
      }
      if (_lastNameController.text.trim().isEmpty) {
        _errors['lastName'] = 'Last name is required';
        valid = false;
      }
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(_emailController.text.trim())) {
        _errors['email'] = 'Enter a valid email address';
        valid = false;
      }
    } else if (_currentStep == 1) {
      if (_passwordController.text.length < 8) {
        _errors['password'] = 'Password must be at least 8 characters';
        valid = false;
      }
      if (_confirmPasswordController.text != _passwordController.text) {
        _errors['confirmPassword'] = 'Passwords do not match';
        valid = false;
      }
      if (!_agreedToTerms) {
        _errors['terms'] = 'You must agree to the Terms & Privacy Policy';
        valid = false;
      }
    }

    return valid;
  }

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_validateCurrentStep()) return;
    setState(() => _isLoading = true);

    try {
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      await AuthService.instance.register(
        fullName:    fullName,
        email:       _emailController.text.trim(),
        password:    _passwordController.text,
        role:        'Driver',
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      if (!mounted) return;
      // ✅ Show success screen, then pop back to sign-in
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.statusCode == 409) {
        // Email already registered — go back to step 1 and highlight email field
        setState(() {
          _errors['email'] = 'This email is already registered. Sign in instead.';
          _currentStep = 0;
          _progressAnim = Tween<double>(begin: 0, end: 1 / _totalSteps)
              .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
          _progressController.forward(from: 0);
        });
        _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      } else if (e.statusCode == 400) {
        setState(() => _errors['email'] = e.userMessage);
      } else {
        // Generic error — show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorContainer,
            content: Text(e.userMessage,
                style: const TextStyle(color: AppColors.onSurface)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorContainer,
          content: const Text('Cannot connect to server. Is the backend running?',
              style: TextStyle(color: AppColors.onSurface)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final auth = AuthService.instance;
      await auth.loginWithGoogle();
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-up failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Password strength ────────────────────────────────────────────────────────
  double _passwordStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    double score = 0;
    if (pwd.length >= 8) score += 0.25;
    if (pwd.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) score += 0.2;
    return score.clamp(0.0, 1.0);
  }

  Color _strengthColor(double strength) {
    if (strength < 0.35) return AppColors.error;
    if (strength < 0.65) return const Color(0xFFFFB800);
    return AppColors.primary;
  }

  String _strengthLabel(double strength) {
    if (strength < 0.35) return 'Weak';
    if (strength < 0.65) return 'Fair';
    if (strength < 0.85) return 'Strong';
    return 'Excellent';
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (_isSuccess) return _buildSuccessView(topPad);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Fixed header
            _buildHeader(topPad),
            // Progress bar
            _buildProgressBar(),
            // Step indicator
            _buildStepIndicator(),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            // Bottom nav buttons
            _buildBottomButtons(bottomPad),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(double topPad) {
    final stepTitles = ['Account Info', 'Security Setup', 'Your EV Profile'];
    final stepSubs = [
      'Tell us who you are',
      'Create a secure password',
      'Add your electric vehicle',
    ];

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: topPad + 4, left: 16, right: 16, bottom: 12),
      child: Column(
        children: [
          // Status + Back row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _currentStep == 0 ? () => Navigator.pop(context) : _prevStep,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.onSurface),
                ),
              ),
              const SizedBox(width: 36), // Balance placeholder
            ],
          ),
          const SizedBox(height: 16),
          // Branding row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 22, color: AppColors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ChargeSync',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.005,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('EV',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.06,
                            )),
                      ),
                    ],
                  ),
                  Text(
                    'Create Account',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Step counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Step title
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepTitles[_currentStep],
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stepSubs[_currentStep],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Container(
      height: 3,
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (_, __) => FractionallySizedBox(
          widthFactor: _progressAnim.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondaryContainer],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step dots ────────────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primary.withOpacity(0.5)
                  : isActive
                      ? AppColors.primary
                      : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 7, color: AppColors.onPrimary)
                : null,
          );
        }),
      ),
    );
  }

  // ── Step 1: Account Info ─────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Name row
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'First Name',
                  controller: _firstNameController,
                  hint: 'Maya',
                  icon: Icons.person_rounded,
                  errorKey: 'firstName',
                  inputType: TextInputType.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  hint: 'Chen',
                  icon: Icons.person_outline_rounded,
                  errorKey: 'lastName',
                  inputType: TextInputType.name,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Email Address',
            subLabel: 'Your primary account',
            controller: _emailController,
            hint: 'maya@chargesync.network',
            icon: Icons.mail_rounded,
            errorKey: 'email',
            inputType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Phone Number',
            subLabel: 'Optional',
            controller: _phoneController,
            hint: '+1 (555) 000-0000',
            icon: Icons.phone_rounded,
            errorKey: 'phone',
            inputType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          // Google sign-up option
          _buildSocialOption(),
          const SizedBox(height: 12),
          _buildOrDivider(),
          const SizedBox(height: 4),
          _buildAlreadyHaveAccount(),
        ],
      ),
    );
  }

  // ── Step 2: Security ─────────────────────────────────────────────────────────
  Widget _buildStep2() {
    final strength = _passwordStrength(_passwordController.text);
    final strengthColor = _strengthColor(strength);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password
          _buildLabel('Password', null),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _passwordController,
            hint: 'Min. 8 characters',
            obscure: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            errorKey: 'password',
            onChanged: (_) => setState(() {}),
          ),
          if (_errors['password'] != null) ...[
            const SizedBox(height: 6),
            _buildFieldError(_errors['password']!),
          ],
          const SizedBox(height: 10),

          // Strength bar
          if (_passwordController.text.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Password strength',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
                Text(
                  _strengthLabel(strength),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: strengthColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Password requirements
          _buildRequirements(),
          const SizedBox(height: 16),

          // Confirm password
          _buildLabel('Confirm Password', null),
          const SizedBox(height: 6),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            errorKey: 'confirmPassword',
            onChanged: (_) => setState(() {}),
          ),
          if (_errors['confirmPassword'] != null) ...[
            const SizedBox(height: 6),
            _buildFieldError(_errors['confirmPassword']!),
          ],
          const SizedBox(height: 20),

          // Terms checkbox
          _buildTermsRow(),
          if (_errors['terms'] != null) ...[
            const SizedBox(height: 6),
            _buildFieldError(_errors['terms']!),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirements() {
    final pwd = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Requirements',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.04,
              )),
          const SizedBox(height: 8),
          _reqRow('At least 8 characters', pwd.length >= 8),
          _reqRow('Uppercase letter (A–Z)', RegExp(r'[A-Z]').hasMatch(pwd)),
          _reqRow('Number (0–9)', RegExp(r'[0-9]').hasMatch(pwd)),
          _reqRow('Special character (!@#\$...)', RegExp(r'[!@#\$%^&*]').hasMatch(pwd)),
        ],
      ),
    );
  }

  Widget _reqRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: met ? AppColors.primary : AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              met ? Icons.check_rounded : Icons.remove_rounded,
              size: 10,
              color: met ? AppColors.onPrimary : AppColors.outline,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: met ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreedToTerms
                  ? AppColors.primary
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
              border: _agreedToTerms
                  ? null
                  : Border.all(color: AppColors.outline, width: 1.5),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check_rounded,
                    size: 14, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(
                      text:
                          '. Your EV data is encrypted and never sold.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Vehicle ──────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle illustration banner
          _buildVehicleBanner(),
          const SizedBox(height: 20),

          // Make
          _buildDropdownField(
            label: 'Vehicle Make',
            icon: Icons.directions_car_rounded,
            value: _selectedMake,
            items: _carMakes,
            onChanged: (v) {
              setState(() {
                _selectedMake = v!;
                _selectedModel = _carModels[v]!.first;
                // Auto-set connector
                if (v == 'Tesla') _selectedConnector = 'NACS (Tesla)';
                else if (v == 'Rivian') _selectedConnector = 'NACS (Tesla)';
                else _selectedConnector = 'CCS1';
              });
            },
          ),
          const SizedBox(height: 14),

          // Model
          _buildDropdownField(
            label: 'Vehicle Model',
            icon: Icons.electric_car_rounded,
            value: _selectedModel,
            items: _carModels[_selectedMake] ?? [],
            onChanged: (v) => setState(() => _selectedModel = v!),
          ),
          const SizedBox(height: 14),

          // Year + Connector row
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Year',
                  controller: _vehicleYearController,
                  hint: '2024',
                  icon: Icons.calendar_today_rounded,
                  errorKey: 'year',
                  inputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Connector',
                  icon: Icons.power_rounded,
                  value: _selectedConnector,
                  items: _connectors,
                  onChanged: (v) => setState(() => _selectedConnector = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildField(
            label: 'License Plate',
            subLabel: 'Optional',
            controller: _licensePlateController,
            hint: '7ABC123',
            icon: Icons.credit_card_rounded,
            errorKey: 'plate',
            inputType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
          ),
          const SizedBox(height: 20),

          // Skip option
          Center(
            child: GestureDetector(
              onTap: _handleSubmit,
              child: Text(
                'Skip for now — add vehicle later',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryContainer.withOpacity(0.25),
            AppColors.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedMake $_selectedModel',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.power_rounded,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _selectedConnector,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Opacity(
                        opacity:
                            (1 - _pulseController.value).clamp(0.0, 1.0),
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
                    const SizedBox(width: 5),
                    Text(
                      'Compatible with 14+ stations nearby',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.electric_car_rounded,
                size: 32, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ── Bottom buttons ────────────────────────────────────────────────────────────
  Widget _buildBottomButtons(double bottomPad) {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _prevStep,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface, size: 20),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : (isLastStep ? _handleSubmit : _nextStep),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
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
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Creating account...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: ValueKey(_currentStep),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastStep ? 'Create My Account' : 'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLastStep
                                  ? Icons.bolt_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.onPrimary,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success view ──────────────────────────────────────────────────────────────
  Widget _buildSuccessView(double topPad) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(32, topPad, 32, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 30, color: AppColors.onPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to ChargeSync!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your EV account is ready.\nTelemetry sync is now active.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Opacity(
                      opacity: (1 - _pulseController.value).clamp(0, 1.0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Redirecting you to sign in...',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable field widgets ────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    String? subLabel,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String errorKey,
    required TextInputType inputType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    final hasError = _errors[errorKey] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: hasError
                ? AppColors.errorContainer.withOpacity(0.1)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.error.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 18, color: AppColors.outline),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: inputType,
                  inputFormatters: inputFormatters,
                  onChanged: (v) {
                    if (_errors[errorKey] != null) {
                      setState(() => _errors.remove(errorKey));
                    }
                    onChanged?.call(v);
                  },
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.outline),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          _buildFieldError(_errors[errorKey]!),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String errorKey,
    void Function(String)? onChanged,
  }) {
    final hasError = _errors[errorKey] != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.errorContainer.withOpacity(0.1)
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.error.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.lock_rounded, size: 18, color: AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onChanged: (v) {
                if (_errors[errorKey] != null) {
                  setState(() => _errors.remove(errorKey));
                }
                onChanged?.call(v);
              },
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.outline),
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 19,
                color: AppColors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, null),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.outline),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surfaceContainerHigh,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.outline, size: 20),
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.onSurface),
                  items: items
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.onSurface))))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, String? subLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface)),
        if (subLabel != null)
          Text(subLabel,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildFieldError(String message) {
    return Row(
      children: [
        const Icon(Icons.error_rounded, size: 14, color: AppColors.error),
        const SizedBox(width: 5),
        Flexible(
          child: Text(message,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.error)),
        ),
      ],
    );
  }

  Widget _buildSocialOption() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleSignUp,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text('Sign up with Google',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
            child: Container(height: 1, color: AppColors.surfaceContainerHighest)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.outline,
                  letterSpacing: 0.06)),
        ),
        Expanded(
            child: Container(height: 1, color: AppColors.surfaceContainerHighest)),
      ],
    );
  }

  Widget _buildAlreadyHaveAccount() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'Already have an account? ',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.onSurfaceVariant),
            children: [
              TextSpan(
                text: 'Sign In',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google logo painter ────────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final rect = Rect.fromLTWH(0, 0, w, h);
    const pi = 3.14159265358979;

    void drawArc(double start, double sweep, Color color) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, start * pi / 180, sweep * pi / 180, false)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    drawArc(-90, 90, const Color(0xFF4285F4));
    drawArc(0, 90, const Color(0xFF34A853));
    drawArc(90, 90, const Color(0xFFFBBC05));
    drawArc(180, 90, const Color(0xFFEA4335));

    // White inner
    canvas.drawCircle(center, w * 0.35, Paint()..color = AppColors.surfaceContainer);
    // Blue right bar
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - h * 0.1, w * 0.5, h * 0.2),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
