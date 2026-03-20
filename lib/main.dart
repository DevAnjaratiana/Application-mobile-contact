import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as web;

void main() {
  runApp(const ContactApp());
}

// ─────────────────────────────────────────────
//  MODÈLE
// ─────────────────────────────────────────────

class Contact {
  final String id;
  String nom;
  String prenom;
  String telephone;
  String email;
  Color couleur;

  Contact({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.couleur,
  });

  String get nomComplet => '$prenom $nom'.trim();

  String get initiales {
    String i = '';
    if (prenom.isNotEmpty) i += prenom[0];
    if (nom.isNotEmpty) i += nom[0];
    return i.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'email': email,
        'couleur': couleur.value,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: j['id'],
        nom: j['nom'] ?? '',
        prenom: j['prenom'] ?? '',
        telephone: j['telephone'] ?? '',
        email: j['email'] ?? '',
        couleur: Color(j['couleur'] ?? 0xFF6366F1),
      );
}

// ─────────────────────────────────────────────
//  STOCKAGE (localStorage via dart:js_interop)
// ─────────────────────────────────────────────

class ContactStore {
  static const _key = 'flutter_contacts';

  static List<Contact> load() {
    try {
      final raw = web.window.localStorage.getItem(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => Contact.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static void save(List<Contact> contacts) {
    try {
      final data = jsonEncode(contacts.map((c) => c.toJson()).toList());
      web.window.localStorage.setItem(_key, data);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────
//  COULEURS AVATARS
// ─────────────────────────────────────────────

const List<Color> avatarColors = [
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFFEF4444),
  Color(0xFF3B82F6),
];

// ─────────────────────────────────────────────
//  APP
// ─────────────────────────────────────────────

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ContactListPage(),
    );
  }
}

// ─────────────────────────────────────────────
//  PAGE LISTE
// ─────────────────────────────────────────────

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contacts = ContactStore.load();
    _contacts.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    _filtered = List.from(_contacts);
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _contacts
          .where((c) =>
              c.nomComplet.toLowerCase().contains(q) ||
              c.telephone.contains(q) ||
              c.email.toLowerCase().contains(q))
          .toList();
    });
  }

  void _save() => ContactStore.save(_contacts);

  void _openForm({Contact? contact}) async {
    final result = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormPage(contact: contact),
      ),
    );
    if (result != null) {
      setState(() {
        if (contact != null) {
          final i = _contacts.indexWhere((c) => c.id == result.id);
          if (i != -1) _contacts[i] = result;
        } else {
          _contacts.add(result);
        }
        _contacts.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
        _filter();
      });
      _save();
    }
  }

  void _openDetail(Contact contact) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactDetailPage(
          contact: contact,
          onEdit: () => _openForm(contact: contact),
        ),
      ),
    );
    if (deleted == true) {
      setState(() {
        _contacts.removeWhere((c) => c.id == contact.id);
        _filter();
      });
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mes Contacts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${_contacts.length}',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      _contacts.isEmpty
                          ? 'Aucun contact\nAppuyez sur + pour en ajouter'
                          : 'Aucun résultat',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ContactCard(
                    contact: _filtered[i],
                    onTap: () => _openDetail(_filtered[i]),
                  ),
                  childCount: _filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau contact'),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CARTE CONTACT
// ─────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _ContactCard({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: _Avatar(contact: contact, size: 48),
        title: Text(
          contact.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          contact.telephone,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[300]),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AVATAR
// ─────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Contact contact;
  final double size;

  const _Avatar({required this.contact, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: contact.couleur,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          contact.initiales,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PAGE DÉTAIL
// ─────────────────────────────────────────────

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;

  const ContactDetailPage({
    super.key,
    required this.contact,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: contact.couleur,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer'),
                      content: Text('Supprimer ${contact.nomComplet} ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: contact.couleur,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    _Avatar(contact: contact, size: 90),
                    const SizedBox(height: 12),
                    Text(
                      contact.nomComplet,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoCard(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: contact.telephone,
                    color: contact.couleur,
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: contact.email.isEmpty ? '—' : contact.email,
                    color: contact.couleur,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FORMULAIRE
// ─────────────────────────────────────────────

class ContactFormPage extends StatefulWidget {
  final Contact? contact;
  const ContactFormPage({super.key, this.contact});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nom;
  late TextEditingController _prenom;
  late TextEditingController _tel;
  late TextEditingController _email;
  late Color _couleur;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nom    = TextEditingController(text: c?.nom ?? '');
    _prenom = TextEditingController(text: c?.prenom ?? '');
    _tel    = TextEditingController(text: c?.telephone ?? '');
    _email  = TextEditingController(text: c?.email ?? '');
    _couleur = c?.couleur ?? avatarColors[0];
  }

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _tel.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final contact = Contact(
      id: widget.contact?.id ?? const Uuid().v4(),
      nom: _nom.text.trim(),
      prenom: _prenom.text.trim(),
      telephone: _tel.text.trim(),
      email: _email.text.trim(),
      couleur: _couleur,
    );
    Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: _couleur,
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Modifier le contact' : 'Nouveau contact'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _couleur,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    () {
                      String i = '';
                      if (_prenom.text.isNotEmpty) i += _prenom.text[0];
                      if (_nom.text.isNotEmpty) i += _nom.text[0];
                      return i.toUpperCase().isEmpty ? '?' : i.toUpperCase();
                    }(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: avatarColors.map((c) {
                final selected = c == _couleur;
                return GestureDetector(
                  onTap: () => setState(() => _couleur = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            _field(_prenom, 'Prénom', Icons.person_outline,
                required: true, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            _field(_nom, 'Nom', Icons.person,
                required: true, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            _field(_tel, 'Téléphone', Icons.phone_outlined,
                required: true, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_email, 'Email', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _couleur,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? 'Enregistrer les modifications' : 'Ajouter le contact',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: _couleur),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _couleur, width: 2),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null
          : null,
    );
  }
}