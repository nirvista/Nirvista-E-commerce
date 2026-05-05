import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pet_shop/base/constant.dart';
import 'package:pet_shop/base/get/login_data_controller.dart';
import 'package:pet_shop/base/get/route_key.dart';
import 'package:pet_shop/services/vendor_api.dart';

const _kTeal = Color(0xFF0D9488);
const _kTealDark = Color(0xFF0F766E);
const _kTealLight = Color(0xFFCCFBF1);
const _kBg = Color(0xFFF4F7F6);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE2EAE8);
const _kText = Color(0xFF0F2622);
const _kTextMuted = Color(0xFF6B8680);
const _kRed = Color(0xFFEF4444);

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _loginController = Get.find<LoginDataController>();
  final _formKey = GlobalKey<FormState>();

  final _storeName = TextEditingController();
  final _storeDescription = TextEditingController();
  final _businessEmail = TextEditingController();
  final _businessPhone = TextEditingController();
  final _businessAddress = TextEditingController();
  final _businessRegistrationNumber = TextEditingController();
  final _businessRegistrationDocUrl = TextEditingController();
  final _taxId = TextEditingController();
  final _bankAccountName = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankName = TextEditingController();
  final _bankIFSC = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _storeName.dispose();
    _storeDescription.dispose();
    _businessEmail.dispose();
    _businessPhone.dispose();
    _businessAddress.dispose();
    _businessRegistrationNumber.dispose();
    _businessRegistrationDocUrl.dispose();
    _taxId.dispose();
    _bankAccountName.dispose();
    _bankAccountNumber.dispose();
    _bankName.dispose();
    _bankIFSC.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _emailValidator(String? v) {
    final req = _required(v, 'Business email');
    if (req != null) return req;
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(v!.trim())) return 'Enter a valid email';
    return null;
  }

  String? _phoneValidator(String? v) {
    final req = _required(v, 'Business phone');
    if (req != null) return req;
    final digits = v!.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Enter a valid phone number';
    return null;
  }

  String? _urlValidator(String? v) {
    final req = _required(v, 'Registration document URL');
    if (req != null) return req;
    final trimmed = v!.trim();
    if (!(trimmed.startsWith('http://') || trimmed.startsWith('https://'))) {
      return 'URL must start with http:// or https://';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _loginController.accessToken;

    if (token == null || token.isEmpty) {
      _snack('Session expired. Please login again.', isError: true);
      return;
    }

    setState(() => _submitting = true);

    final payload = {
      'storeName': _storeName.text.trim(),
      'storeDescription': _storeDescription.text.trim(),
      'businessEmail': _businessEmail.text.trim(),
      'businessPhone': _businessPhone.text.trim(),
      'businessAddress': _businessAddress.text.trim(),
      'businessRegistrationNumber': _businessRegistrationNumber.text.trim(),
      'businessRegistrationDocUrl': _businessRegistrationDocUrl.text.trim(),
      'taxId': _taxId.text.trim(),
      'bankAccountName': _bankAccountName.text.trim(),
      'bankAccountNumber': _bankAccountNumber.text.trim(),
      'bankName': _bankName.text.trim(),
      'bankIFSC': _bankIFSC.text.trim(),
    };

    try {
      final result =
          await VendorApiService.createVendorProfile(token, payload);

      if (!mounted) return;
      setState(() => _submitting = false);

      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, vendorApprovalRoute);
        return;
      }

      final msg = (result['message'] ?? '').toLowerCase();

      if (msg.contains('already exists')) {
        Navigator.pushReplacementNamed(context, vendorApprovalRoute);
        return;
      }

      _snack(result['message'] ?? "Failed", isError: true);
    } catch (e) {
      setState(() => _submitting = false);
      _snack("Network error: $e", isError: true);
    }
  }

  void _snack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _logout() {
    _loginController.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      loginRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kTealDark,
        elevation: 0,
        title: const Text(
          'Vendor Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _sectionCard(
                    title: 'Store Information',
                    icon: Icons.storefront_outlined,
                    fields: [
                      _tf(_storeName, 'Store Name', Icons.store_outlined),
                      _tf(_storeDescription, 'Store Description',
                          Icons.description_outlined,
                          maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Contact Details',
                    icon: Icons.contacts_outlined,
                    fields: [
                      _tf(_businessEmail, 'Business Email',
                          Icons.email_outlined,
                          validator: _emailValidator,
                          keyboardType: TextInputType.emailAddress),
                      _tf(_businessPhone, 'Phone Number',
                          Icons.phone_outlined,
                          validator: _phoneValidator,
                          keyboardType: TextInputType.phone),
                      _tf(_businessAddress, 'Business Address',
                          Icons.location_on_outlined,
                          maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Business Registration',
                    icon: Icons.business_center_outlined,
                    fields: [
                      _tf(_businessRegistrationNumber, 'Registration Number',
                          Icons.badge_outlined),
                      _tf(_businessRegistrationDocUrl,
                          'Registration Doc URL', Icons.link_outlined,
                          validator: _urlValidator,
                          keyboardType: TextInputType.url),
                      _tf(_taxId, 'Tax ID', Icons.receipt_long_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Bank Details',
                    icon: Icons.account_balance_outlined,
                    fields: [
                      _tf(_bankAccountName, 'Account Holder Name',
                          Icons.person_outline),
                      _tf(_bankAccountNumber, 'Account Number',
                          Icons.credit_card_outlined,
                          keyboardType: TextInputType.number),
                      _tf(_bankName, 'Bank Name',
                          Icons.account_balance_outlined),
                      _tf(_bankIFSC, 'IFSC Code',
                          Icons.tag_outlined),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kTealDark, _kTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Set Up Your Vendor Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill in your details to get approved and start selling',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Text(
              '4 sections  ·  Takes ~2 mins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kTealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _kTeal, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: fields),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _submitting
            ? null
            : const LinearGradient(
                colors: [_kTealDark, _kTeal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _submitting ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _submitting
            ? []
            : [
                BoxShadow(
                  color: _kTeal.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitting ? null : _submit,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _kTeal,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Submit for Approval',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController c,
    String label,
    IconData prefixIcon, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: c,
        validator: validator ?? (v) => _required(v, label),
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: _kText, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _kTextMuted, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: _kTextMuted, size: 20),
          filled: true,
          fillColor: _kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kTeal, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kRed, width: 1.8),
          ),
        ),
      ),
    );
  }
}
