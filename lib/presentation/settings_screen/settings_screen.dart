import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(String)? onNameUpdated;
  final Function(String)? onAvatarUpdated;

  const SettingsScreen({
    super.key,
    required this.userData,
    this.onNameUpdated,
    this.onAvatarUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _auth     = AuthRepository();
  final _supabase = Supabase.instance.client;

  // Profile
  String _name             = '';
  String _avatarUrl        = '';
  int    _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
  bool   _uploadingAvatar  = false;

  // Subjects — V2 canonical list
  final List<String> _allSubjects = [
    'Physics', 'Chemistry', 'Biology', 'Mathematics',
    'English Language', 'English Literature', 'Hindi',
    'Geography', 'History & Civics', 'Computer Applications',
  ];
  List<String> _favSubjects    = [];
  List<String> _boringSubjects = [];
  bool _isSavingSubjects = false;

  // Name
  final _nameController = TextEditingController();
  bool _isSavingName    = false;

  // Password
  final _newPassController     = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isSavingPass   = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _name      = widget.userData['name']      as String? ?? '';
    _avatarUrl = widget.userData['avatarUrl'] as String? ?? '';
    _nameController.text = _name;
    _loadSubjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── Data (unchanged) ───────────────────────────────────────────────────────

  Future<void> _loadSubjects() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final data = await _supabase
          .from('profiles')
          .select('name, fav_subjects, boring_subjects, avatar_url')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _name                = data['name']      as String? ?? _name;
          _nameController.text = _name;
          _favSubjects    = List<String>.from(data['fav_subjects']    ?? []);
          _boringSubjects = List<String>.from(data['boring_subjects'] ?? []);
          _avatarUrl      = data['avatar_url'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  // ── Actions (unchanged logic) ──────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, maxHeight: 512, imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final file = File(image.path);
      final ext  = image.path.split('.').last.toLowerCase();
      final path = '${user.id}/avatar.$ext';
      await _supabase.storage.from('avatar').upload(
        path, file,
        fileOptions: const FileOptions(upsert: true),
      );
      final publicUrl =
      _supabase.storage.from('avatar').getPublicUrl(path);
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);
      if (mounted) {
        setState(() {
          _avatarUrl        = publicUrl;
          _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
        });
        widget.onAvatarUpdated
            ?.call('$publicUrl?t=$_avatarCacheBuster');
        _ok('Profile photo updated');
      }
    } catch (e) {
      debugPrint('❌ AVATAR ERROR: $e');
      if (mounted) _err('Failed to upload photo.');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { _err('Name cannot be empty.'); return; }
    setState(() => _isSavingName = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase
          .from('profiles')
          .update({'name': name})
          .eq('id', user.id);
      if (mounted) {
        setState(() => _name = name);
        widget.onNameUpdated?.call(name);
        _ok('Name updated');
      }
    } catch (_) {
      if (mounted) _err('Failed to update name.');
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _savePassword() async {
    final newPwd     = _newPassController.text;
    final confirmPwd = _confirmPassController.text;
    if (newPwd.length < 6) { _err('Minimum 6 characters.'); return; }
    if (newPwd != confirmPwd) { _err('Passwords do not match.'); return; }
    setState(() => _isSavingPass = true);
    try {
      await _supabase.auth
          .updateUser(UserAttributes(password: newPwd));
      _newPassController.clear();
      _confirmPassController.clear();
      if (mounted) _ok('Password changed');
    } catch (_) {
      if (mounted) _err('Failed to change password.');
    } finally {
      if (mounted) setState(() => _isSavingPass = false);
    }
  }

  Future<void> _saveSubjects() async {
    setState(() => _isSavingSubjects = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase.from('profiles').update({
        'fav_subjects':    _favSubjects,
        'boring_subjects': _boringSubjects,
      }).eq('id', user.id);
      if (mounted) _ok('Preferences saved');
    } catch (_) {
      if (mounted) _err('Failed to save.');
    } finally {
      if (mounted) setState(() => _isSavingSubjects = false);
    }
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────

  void _ok(String msg)  => _snackbar(msg, AppTheme.success, Icons.check_circle_outline_rounded);
  void _err(String msg) => _snackbar(msg, AppTheme.danger,  Icons.error_outline_rounded);

  void _snackbar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 3),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.dmSans(
              color: AppTheme.textPrimary, fontSize: 13))),
        ]),
      ),
    ));
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
              color: AppTheme.borderDefault, width: 0.5),
        ),
        title: Text('Sign out?',
            style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 17)),
        content: Text(
            'Your streak and study data are safely stored.',
            style: GoogleFonts.dmSans(
                color: AppTheme.textMuted, fontSize: 13, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (r) => false);
              }
            },
            child: Text('Sign out',
                style: GoogleFonts.dmSans(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Sheets (logic unchanged, visuals updated) ─────────────────────────────

  void _showFeaturesSheet() =>
      _sheet('What\'s in Focus Forge', 'Built for study discipline', [
        _feat(Icons.local_fire_department_outlined, 'Streak Tracking',
            'Study 2+ hours daily. Miss a day and it resets.'),
        _feat(Icons.timer_outlined, 'Focus Sessions',
            'Timer-based sessions with subject and topic tracking.'),
        _feat(Icons.music_note_outlined, 'Study Music',
            'Built-in lo-fi, rain, nature and ambient tracks.'),
        _feat(Icons.bar_chart_rounded, 'Analytics',
            'Weekly charts showing time spent per subject.'),
        _feat(Icons.check_box_outlined, 'Task Manager',
            'To-do list with deadline scheduling.'),
        _feat(Icons.nights_stay_outlined, 'Midnight Reset',
            'Live countdown to complete today\'s 2-hour goal.'),
        const SizedBox(height: 24),
      ]);

  void _showPrivacy() => _textSheet('Privacy Policy', '''Last updated: May 2025

1. DATA WE COLLECT
FocusForge collects only what's necessary: your email, display name, study session data, and streak information.

2. HOW WE USE YOUR DATA
Your data powers your personal dashboard. We do not sell, share, or monetize your data.

3. DATA STORAGE
All data is securely stored on Supabase with encryption at rest and in transit.

4. YOUR RIGHTS
You may request deletion of your account at any time within 30 days.

5. CONTACT
arnavchandra360@gmail.com''');

  void _showTerms() => _textSheet('Terms of Service', '''Last updated: May 2025

1. ACCEPTANCE
By using FocusForge, you agree to these terms.

2. ELIGIBILITY
Can be used only by the founder's friend.

3. ACCOUNT RESPONSIBILITY
Keep your credentials confidential. Do not share your account.

4. ACCEPTABLE USE
Do not misuse, hack, or exploit the app in any way.

5. STUDY DATA
Your sessions and streaks belong to you.

6. CONTACT
arnavchandra360@gmail.com''');

  void _sheet(
      String title, String sub, List<Widget> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (_, ctrl) =>
            _sheetWrap(title, sub, ctrl, items),
      ),
    );
  }

  void _textSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => _sheetWrap(title, '', ctrl, [
          Text(content,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.8)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _sheetWrap(String title, String sub,
      ScrollController ctrl, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
            top: BorderSide(
                color: AppTheme.borderDefault, width: 0.5)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 3,
          decoration: BoxDecoration(
              color: AppTheme.borderDefault,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(sub,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            children: items,
          ),
        ),
      ]),
    );
  }

  Widget _feat(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accentTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(desc,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHero()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            child: Column(children: [
              const SizedBox(height: 24),
              _SectionLabel(label: 'Account'),
              const SizedBox(height: 10),
              _buildAccountCard(),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Study preferences'),
              const SizedBox(height: 10),
              _buildSubjectsCard(),
              const SizedBox(height: 24),
              _SectionLabel(label: 'App info'),
              const SizedBox(height: 10),
              _buildAppCard(),
              const SizedBox(height: 24),
              _buildLogoutBtn(),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    final initials = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    final streak   = widget.userData['streak'] as int? ?? 0;
    final email    = widget.userData['email']  as String? ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            // ── Avatar ──
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: Stack(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentTint,
                    border: Border.all(
                        color: AppTheme.borderDefault, width: 0.5),
                  ),
                  child: ClipOval(
                    child: _uploadingAvatar
                        ? const Center(
                      child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent),
                      ),
                    )
                        : _avatarUrl.isNotEmpty
                        ? Image.network(
                      '$_avatarUrl?t=$_avatarCacheBuster',
                      width: 64, height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(initials,
                            style: GoogleFonts.instrumentSerif(
                                color: AppTheme.accent,
                                fontSize: 24,
                                fontWeight: FontWeight.w400)),
                      ),
                    )
                        : Center(
                      child: Text(initials,
                          style: GoogleFonts.instrumentSerif(
                              color: AppTheme.accent,
                              fontSize: 24,
                              fontWeight: FontWeight.w400)),
                    ),
                  ),
                ),
                // Camera badge
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.backgroundPrimary, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
              ]),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name.isEmpty ? '—' : _name,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(email,
                      style: GoogleFonts.dmSans(
                          color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.danger.withOpacity(0.2),
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                            Icons.local_fire_department_rounded,
                            size: 12,
                            color: AppTheme.danger),
                        const SizedBox(width: 5),
                        Text('$streak day streak',
                            style: GoogleFonts.dmSans(
                                color: AppTheme.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Account Card ──────────────────────────────────────────────────────────

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(children: [
        // Name
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel(label: 'Display name'),
              const SizedBox(height: 10),
              _SettingsInput(
                controller: _nameController,
                hint: 'Your name',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Save name',
                loading: _isSavingName,
                onTap: _saveName,
              ),
            ],
          ),
        ),

        const Divider(
            color: AppTheme.borderSubtle, height: 1, thickness: 0.5),

        // Password
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardLabel(label: 'Change password'),
              const SizedBox(height: 10),
              _SettingsInput(
                controller: _newPassController,
                hint: 'New password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 8),
              _SettingsInput(
                controller: _confirmPassController,
                hint: 'Confirm password',
                icon: Icons.lock_reset_rounded,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Update password',
                loading: _isSavingPass,
                onTap: _savePassword,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Subjects Card ─────────────────────────────────────────────────────────

  Widget _buildSubjectsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(label: 'Favourite subjects'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7, runSpacing: 7,
            children: _allSubjects.map((s) {
              final sel = _favSubjects.contains(s);
              return _SubjectChip(
                label: s,
                selected: sel,
                activeColor: AppTheme.accent,
                onTap: () => setState(() {
                  if (sel) {
                    _favSubjects.remove(s);
                  } else {
                    _favSubjects.add(s);
                    _boringSubjects.remove(s);
                  }
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          const Divider(
              color: AppTheme.borderSubtle, height: 1, thickness: 0.5),
          const SizedBox(height: 18),

          _CardLabel(label: 'Avoid / boring'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7, runSpacing: 7,
            children: _allSubjects.map((s) {
              final sel = _boringSubjects.contains(s);
              return _SubjectChip(
                label: s,
                selected: sel,
                activeColor: AppTheme.warning,
                onTap: () => setState(() {
                  if (sel) {
                    _boringSubjects.remove(s);
                  } else {
                    _boringSubjects.add(s);
                    _favSubjects.remove(s);
                  }
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          _ActionButton(
            label: 'Save preferences',
            loading: _isSavingSubjects,
            onTap: _saveSubjects,
          ),
        ],
      ),
    );
  }

  // ── App Card ──────────────────────────────────────────────────────────────

  Widget _buildAppCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(children: [
        _AppRow(
            icon: Icons.auto_awesome_outlined,
            label: 'App features',
            onTap: _showFeaturesSheet),
        const Divider(
            color: AppTheme.borderSubtle,
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16),
        _AppRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy policy',
            onTap: _showPrivacy),
        const Divider(
            color: AppTheme.borderSubtle,
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16),
        _AppRow(
            icon: Icons.description_outlined,
            label: 'Terms of service',
            onTap: _showTerms),
      ]),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Widget _buildLogoutBtn() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.dangerTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.danger.withOpacity(0.2), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.logout_rounded,
              color: AppTheme.danger, size: 18),
          const SizedBox(width: 12),
          Text('Sign out',
              style: GoogleFonts.dmSans(
                  color: AppTheme.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.danger, size: 16),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Local widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String label;
  const _CardLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SettingsInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggle;

  const _SettingsInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.dmSans(
          color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            color: AppTheme.textDisabled, fontSize: 14),
        prefixIcon: Icon(icon,
            color: AppTheme.textMuted, size: 16),
        suffixIcon: onToggle != null
            ? IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.textMuted,
            size: 16,
          ),
          onPressed: onToggle,
        )
            : null,
        filled: true,
        fillColor: AppTheme.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppTheme.borderDefault, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: AppTheme.borderDefault, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppTheme.accent, width: 1.0),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
            ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withOpacity(0.1)
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor.withOpacity(0.4)
                : AppTheme.borderSubtle,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: selected ? activeColor : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: selected
                ? FontWeight.w500
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: AppTheme.textSecondary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.dmSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400)),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textDisabled, size: 16),
        ]),
      ),
    );
  }
}