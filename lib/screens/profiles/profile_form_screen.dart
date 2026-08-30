import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/widgets/app_button.dart';
import 'package:meus_recibos/core/widgets/app_input.dart';
import 'package:meus_recibos/models/profile.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:meus_recibos/services/logo_storage_service.dart';
import 'package:provider/provider.dart';

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({this.profile, super.key});
  final Profile? profile;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _logoStorage = LogoStorageService();
  late final TextEditingController _name;
  late final TextEditingController _tradeName;
  late final TextEditingController _documentNumber;
  late final TextEditingController _serviceType;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late String _documentType;
  late int _color;
  late bool _isDefault;
  String? _selectedLogoPath;
  bool _saving = false;

  Profile? get _profile => widget.profile;

  @override
  void initState() {
    super.initState();
    final profile = _profile;
    _name = TextEditingController(text: profile?.name);
    _tradeName = TextEditingController(text: profile?.tradeName);
    _documentNumber = TextEditingController(text: profile?.documentNumber);
    _serviceType = TextEditingController(text: profile?.serviceType);
    _phone = TextEditingController(text: profile?.phone);
    _email = TextEditingController(text: profile?.email);
    _address = TextEditingController(text: profile?.address);
    _city = TextEditingController(text: profile?.city);
    _state = TextEditingController(text: profile?.state);
    _documentType = profile?.documentType ?? 'CNPJ';
    _color = profile?.color ?? AppColors.primary.toARGB32();
    _isDefault = profile?.isDefault ?? false;
    _selectedLogoPath = profile?.logoPath;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _tradeName,
      _documentNumber,
      _serviceType,
      _phone,
      _email,
      _address,
      _city,
      _state,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _pickLogo() async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (selected != null && mounted) {
      setState(() => _selectedLogoPath = selected.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      var logoPath = _selectedLogoPath;
      if (logoPath != null && logoPath != _profile?.logoPath) {
        logoPath = await _logoStorage.save(logoPath);
      }
      final now = DateTime.now();
      final profile = Profile(
        id: _profile?.id,
        name: _name.text.trim(),
        tradeName: _optional(_tradeName.text),
        documentType: _documentType,
        documentNumber: _documentNumber.text.trim(),
        serviceType: _serviceType.text.trim(),
        phone: _phone.text.trim(),
        email: _optional(_email.text),
        address: _optional(_address.text),
        city: _city.text.trim(),
        state: _state.text.trim().toUpperCase(),
        logoPath: logoPath,
        color: _color,
        isDefault: _isDefault,
        createdAt: _profile?.createdAt ?? now,
        updatedAt: now,
      );
      if (!mounted) return;
      await context.read<ProfileController>().save(profile);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o perfil.')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = _selectedLogoPath;
    final hasLogo = logoPath != null && File(logoPath).existsSync();
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile == null ? 'Novo Perfil' : 'Editar Perfil'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Configure as informações que identificarão sua empresa nos documentos.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickLogo,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    image: hasLogo
                        ? DecorationImage(
                            image: FileImage(File(logoPath)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasLogo
                      ? null
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Selecionar logo'),
            ),
            const _SectionTitle('Dados da empresa'),
            AppInput(
              controller: _name,
              label: 'Nome / Razão Social',
              icon: Icons.business_outlined,
              validator: _required,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _tradeName,
              label: 'Nome fantasia (opcional)',
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    initialValue: _documentType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                      DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ')),
                    ],
                    onChanged: (value) =>
                        setState(() => _documentType = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInput(
                    controller: _documentNumber,
                    label: _documentType,
                    validator: _required,
                    keyboardType: TextInputType.number,
                    textCapitalization: TextCapitalization.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _serviceType,
              label: 'Tipo de serviço prestado',
              icon: Icons.work_outline,
              validator: _required,
            ),
            const _SectionTitle('Contato'),
            AppInput(
              controller: _phone,
              label: 'Telefone / WhatsApp',
              icon: Icons.phone_outlined,
              validator: _required,
              keyboardType: TextInputType.phone,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _email,
              label: 'E-mail (opcional)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
            ),
            const _SectionTitle('Endereço'),
            AppInput(
              controller: _address,
              label: 'Endereço (opcional)',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppInput(
                    controller: _city,
                    label: 'Cidade',
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 92,
                  child: AppInput(
                    controller: _state,
                    label: 'UF',
                    validator: _required,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const _SectionTitle('Cor principal'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColors.profilePalette.map((color) {
                final selected = _color == color.toARGB32();
                return InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => setState(() => _color = color.toARGB32()),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: color,
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Perfil padrão'),
              subtitle: const Text(
                'Usar automaticamente nos novos documentos.',
              ),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Salvar Perfil',
              icon: Icons.save_outlined,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
