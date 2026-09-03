import 'package:flutter/material.dart';
import 'package:meus_recibos/core/theme/app_colors.dart';
import 'package:meus_recibos/core/utils/currency_utils.dart';
import 'package:meus_recibos/core/utils/date_utils.dart';
import 'package:meus_recibos/core/utils/document_utils.dart';
import 'package:meus_recibos/core/utils/quantity_utils.dart';
import 'package:meus_recibos/core/widgets/app_button.dart';
import 'package:meus_recibos/models/app_document.dart';
import 'package:meus_recibos/models/client.dart';
import 'package:meus_recibos/models/document_item.dart';
import 'package:meus_recibos/screens/clients/client_controller.dart';
import 'package:meus_recibos/screens/clients/clients_screen.dart';
import 'package:meus_recibos/screens/documents/document_controller.dart';
import 'package:meus_recibos/screens/profiles/profile_controller.dart';
import 'package:meus_recibos/screens/receipt/receipt_detail_screen.dart';
import 'package:meus_recibos/screens/receipt/receipt_preview_screen.dart';
import 'package:provider/provider.dart';

class ReceiptFormScreen extends StatefulWidget {
  const ReceiptFormScreen({
    this.type = DocumentType.receipt,
    this.initialDocument,
    this.editing = false,
    super.key,
  });

  final DocumentType type;
  final AppDocument? initialDocument;
  final bool editing;

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientName = TextEditingController();
  final _clientDocument = TextEditingController();
  final _clientAddress = TextEditingController();
  final _serviceDescription = TextEditingController();
  final _discount = TextEditingController();
  final _notes = TextEditingController();
  final List<_ItemDraft> _items = [];
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  int? _profileId;
  int? _initialClientId;
  Client? _selectedClient;
  String _paymentMethod = 'PIX';
  bool _saveClient = false;
  bool _saving = false;

  bool get _isBudget => widget.type == DocumentType.budget;

  int get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  int get _discountCents => CurrencyUtils.tryParseCents(_discount.text) ?? 0;
  int get _total => (_subtotal - _discountCents).clamp(0, _subtotal);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocument;
    if (initial == null) {
      _items.add(_ItemDraft());
      return;
    }
    _profileId = initial.profileId;
    _initialClientId = initial.clientId;
    _clientName.text = initial.clientName;
    _clientDocument.text = initial.clientDocument ?? '';
    _clientAddress.text = initial.clientAddress ?? '';
    _serviceDescription.text = initial.serviceDescription;
    _discount.text = CurrencyUtils.format(initial.discount)
        .replaceFirst('R\$ ', '');
    _notes.text = initial.notes ?? '';
    _paymentMethod = initial.paymentMethod;
    if (widget.editing) {
      _date = initial.date;
      _dueDate = _isBudget ? initial.validUntil : initial.dueDate;
    }
    _items.addAll(initial.items.map(_ItemDraft.fromItem));
    if (_items.isEmpty) _items.add(_ItemDraft());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileId ??= context.read<ProfileController>().defaultProfile?.id;
  }

  @override
  void dispose() {
    _clientName.dispose();
    _clientDocument.dispose();
    _clientAddress.dispose();
    _serviceDescription.dispose();
    _discount.dispose();
    _notes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _selectClient() async {
    final client = await Navigator.push<Client>(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientsScreen(selectionMode: true),
      ),
    );
    if (client == null || !mounted) return;
    setState(() {
      _selectedClient = client;
      _initialClientId = null;
      _clientName.text = client.name;
      _clientDocument.text = client.document ?? '';
      _clientAddress.text = client.address ?? '';
      _saveClient = false;
    });
  }

  void _clearSelectedClient() {
    setState(() {
      _selectedClient = null;
      _initialClientId = null;
      _clientName.clear();
      _clientDocument.clear();
      _clientAddress.clear();
    });
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  void _addItem() => setState(() => _items.add(_ItemDraft()));

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() => _items.removeAt(index).dispose());
  }

  AppDocument _receiptDraft({int? clientId}) {
    final now = DateTime.now();
    final initial = widget.initialDocument;
    return AppDocument(
      id: widget.editing ? initial?.id : null,
      number: widget.editing ? initial?.number : null,
      sequence: widget.editing ? initial?.sequence : null,
      year: widget.editing ? initial?.year : null,
      type: widget.type,
      profileId: _profileId!,
      clientId: clientId ?? _selectedClient?.id ?? _initialClientId,
      clientName: _clientName.text.trim(),
      clientDocument: _optional(DocumentUtils.digitsOnly(_clientDocument.text)),
      clientAddress: _optional(_clientAddress.text),
      date: _date,
      dueDate: _isBudget ? null : _dueDate,
      validUntil: _isBudget ? _dueDate : null,
      serviceDescription: _serviceDescription.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _optional(_notes.text),
      subtotal: _subtotal,
      discount: _discountCents,
      total: _total,
      status: widget.editing ? initial!.status : (_isBudget ? 'pending' : 'paid'),
      sourceDocumentId: widget.editing
          ? initial?.sourceDocumentId
          : widget.type == DocumentType.proof
          ? initial?.id
          : null,
      pdfPath: widget.editing ? initial?.pdfPath : null,
      createdAt: widget.editing ? initial!.createdAt : now,
      updatedAt: now,
      items: _items.map((item) => item.toDocumentItem()).toList(),
    );
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileId == null || _discountCents > _subtotal) {
      await _save();
      return;
    }
    final profile = context.read<ProfileController>().profiles.firstWhere(
      (profile) => profile.id == _profileId,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPreviewScreen(
          receipt: _receiptDraft(),
          profile: profile,
          onSave: _save,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre ou selecione um perfil antes de salvar.'),
        ),
      );
      return;
    }
    if (_discountCents > _subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O desconto não pode ser maior que o subtotal.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      var clientId = _selectedClient?.id ?? _initialClientId;
      if (_saveClient && _selectedClient == null) {
        final now = DateTime.now();
        final savedClient = await context
            .read<ClientController>()
            .saveFromDocument(
              Client(
                name: _clientName.text.trim(),
                document: _optional(_clientDocument.text),
                address: _optional(_clientAddress.text),
                createdAt: now,
                updatedAt: now,
              ),
            );
        clientId = savedClient.id;
      }
      final receipt = _receiptDraft(clientId: clientId);
      if (!mounted) return;
      final profile = context.read<ProfileController>().profiles.firstWhere(
        (profile) => profile.id == _profileId,
      );
      final saved = await context
          .read<DocumentController>()
          .saveDocumentWithPdf(receipt, profile);
      if (!mounted) return;
      if (widget.editing) {
        final navigator = Navigator.of(context);
        navigator.popUntil((route) => route.isFirst);
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => ReceiptDetailScreen(receipt: saved),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptDetailScreen(receipt: saved),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível salvar o ${widget.type.label.toLowerCase()}.',
            ),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ProfileController>().profiles;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.editing ? 'Editar' : 'Novo'} ${widget.type.label}',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionTitle('Documento'),
              DropdownButtonFormField<int>(
                initialValue:
                    profiles.any((profile) => profile.id == _profileId)
                    ? _profileId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Perfil emissor',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                items: profiles
                    .map(
                      (profile) => DropdownMenuItem(
                        value: profile.id,
                        child: Text(profile.tradeName ?? profile.name),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Selecione um perfil' : null,
                onChanged: (value) => setState(() => _profileId = value),
              ),
              const SizedBox(height: 12),
              _DateFields(
                date: _date,
                dueDate: _dueDate,
                dueLabel: _isBudget ? 'Validade' : 'Vencimento',
                onDateTap: () async {
                  final value = await _pickDate(_date);
                  if (value != null) setState(() => _date = value);
                },
                onDueTap: () async {
                  final value = await _pickDate(_dueDate ?? _date);
                  if (value != null) setState(() => _dueDate = value);
                },
                onDueClear: () => setState(() => _dueDate = null),
              ),
              const _SectionTitle('Dados do cliente'),
              OutlinedButton.icon(
                onPressed: _selectClient,
                icon: const Icon(Icons.person_search_outlined),
                label: Text(
                  _selectedClient == null
                      ? 'Selecionar cliente cadastrado'
                      : 'Trocar cliente selecionado',
                ),
              ),
              if (_selectedClient != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _clearSelectedClient,
                    child: const Text('Limpar seleção'),
                  ),
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _clientName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientDocument,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CPF/CNPJ (opcional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientAddress,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Endereço (opcional)',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 38),
                    child: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
              if (_selectedClient == null && _initialClientId == null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveClient,
                  onChanged: (value) =>
                      setState(() => _saveClient = value ?? false),
                  title: const Text('Salvar cliente para reutilizar'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const _SectionTitle('Serviço'),
              TextFormField(
                controller: _serviceDescription,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrição do serviço (opcional)',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 38),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Text(
                    'Itens',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar item'),
                  ),
                ],
              ),
              ...List.generate(
                _items.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ItemCard(
                    draft: _items[index],
                    canRemove: _items.length > 1,
                    onChanged: () => setState(() {}),
                    onRemove: () => _removeItem(index),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _TotalLine(
                      label: 'Subtotal',
                      value: CurrencyUtils.format(_subtotal),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Desconto',
                        prefixText: 'R\$ ',
                      ),
                      validator: (value) {
                        final cents =
                            CurrencyUtils.tryParseCents(value ?? '') ?? 0;
                        return cents > _subtotal
                            ? 'Maior que o subtotal'
                            : null;
                      },
                    ),
                    const Divider(height: 28),
                    _TotalLine(
                      label: 'TOTAL',
                      value: CurrencyUtils.format(_total),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const _SectionTitle('Pagamento'),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Forma de pagamento',
                  prefixIcon: Icon(Icons.payment_outlined),
                ),
                items:
                    const [
                          'PIX',
                          'Dinheiro',
                          'Cartão de crédito',
                          'Cartão de débito',
                          'Transferência',
                          'Boleto',
                          'Outro',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Visualizar e Gerar',
                icon: Icons.picture_as_pdf_outlined,
                loading: _saving,
                onPressed: _preview,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDraft {
  _ItemDraft()
    : description = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      unitPrice = TextEditingController(),
      unit = 'un';

  _ItemDraft.fromItem(DocumentItem item)
    : description = TextEditingController(text: item.description),
      quantity = TextEditingController(
        text: QuantityUtils.formatMillis(item.quantityMillis),
      ),
      unitPrice = TextEditingController(
        text: CurrencyUtils.format(item.unitPrice).replaceFirst('R\$ ', ''),
      ),
      unit = item.unit;

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  String unit;

  int get quantityMillis => QuantityUtils.tryParseMillis(quantity.text) ?? 0;
  int get unitPriceCents => CurrencyUtils.tryParseCents(unitPrice.text) ?? 0;
  int get total => QuantityUtils.calculateTotal(quantityMillis, unitPriceCents);

  DocumentItem toDocumentItem() => DocumentItem(
    description: description.text.trim(),
    quantityMillis: quantityMillis,
    unit: unit,
    unitPrice: unitPriceCents,
    total: total,
  );

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.draft,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });
  final _ItemDraft draft;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: draft.description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descrição do item',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe a descrição'
                      : null,
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Remover item',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: draft.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(labelText: 'Qtd'),
                  validator: (value) =>
                      (QuantityUtils.tryParseMillis(value ?? '') ?? 0) <= 0
                      ? 'Inválida'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: draft.unit,
                  decoration: const InputDecoration(labelText: 'Unid.'),
                  items: const ['un', 'h', 'dia', 'm', 'm²', 'kg', 'serv.']
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) {
                    draft.unit = value!;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.unitPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Valor unitário',
              prefixText: 'R\$ ',
            ),
            validator: (value) =>
                (CurrencyUtils.tryParseCents(value ?? '') ?? 0) <= 0
                ? 'Informe o valor'
                : null,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${CurrencyUtils.format(draft.total)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.optional = false,
    this.onClear,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool optional;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: optional ? '$label (opcional)' : label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: value != null && optional
            ? IconButton(onPressed: onClear, icon: const Icon(Icons.close))
            : null,
      ),
      child: Text(value == null ? 'Selecionar' : AppDateUtils.format(value!)),
    ),
  );
}

class _DateFields extends StatelessWidget {
  const _DateFields({
    required this.date,
    required this.dueDate,
    required this.dueLabel,
    required this.onDateTap,
    required this.onDueTap,
    required this.onDueClear,
  });

  final DateTime date;
  final DateTime? dueDate;
  final String dueLabel;
  final VoidCallback onDateTap;
  final VoidCallback onDueTap;
  final VoidCallback onDueClear;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final vertical = constraints.maxWidth < 360 || textScale > 1.15;
      final dateField = _DateField(
        label: 'Data',
        value: date,
        onTap: onDateTap,
      );
      final dueField = _DateField(
        label: dueLabel,
        value: dueDate,
        optional: true,
        onClear: onDueClear,
        onTap: onDueTap,
      );
      if (vertical) {
        return Column(
          children: [dateField, const SizedBox(height: 12), dueField],
        );
      }
      return Row(
        children: [
          Expanded(child: dateField),
          const SizedBox(width: 12),
          Expanded(child: dueField),
        ],
      );
    },
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
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

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });
  final String label;
  final String value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
          fontSize: emphasized ? 17 : 14,
          color: emphasized ? AppColors.primary : null,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          fontSize: emphasized ? 20 : 15,
          color: emphasized ? AppColors.primary : null,
        ),
      ),
    ],
  );
}
