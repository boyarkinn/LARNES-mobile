import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

Map<String, dynamic> _bankSelection(String value) {
  Map raw = const {};
  try {
    final decoded = jsonDecode(value);
    if (decoded is Map) raw = decoded;
  } catch (_) {
    /* empty field */
  }
  return {
    'libraryId': readingContentBankLibraryId,
    'materialIds': <String>[],
    for (final key in [
      'materialIds',
      'categoryId',
      'locale',
      'kind',
      'hasImage',
    ])
      if (raw[key] != null) key: raw[key],
  };
}

/// The same published bank chooser is used by native parent and admin forms.
class TrainerContentBankField extends StatefulWidget {
  const TrainerContentBankField({
    super.key,
    required this.trainerKey,
    required this.value,
    required this.onChanged,
    this.params = const {},
    this.selectionMode = 'single',
  });
  final String trainerKey;
  final String value;
  final ValueChanged<String> onChanged;
  final Map<String, dynamic> params;
  final String selectionMode;
  @override
  State<TrainerContentBankField> createState() =>
      _TrainerContentBankFieldState();
}

class _TrainerContentBankFieldState extends State<TrainerContentBankField> {
  final _search = TextEditingController();
  Timer? _debounce;
  Map<String, dynamic> _selection = {};
  Map<String, dynamic>? _result;
  final Map<String, String> _materialTitles = {};
  String? _error;
  int _request = 0;
  int _page = 1;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _selection = _bankSelection(widget.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TrainerContentBankField oldWidget) {
    super.didUpdateWidget(oldWidget);
    var selectionChanged = false;
    if (oldWidget.value != widget.value) {
      final incoming = _bankSelection(widget.value);
      if (jsonEncode(incoming) != jsonEncode(_selection)) {
        _selection = incoming;
        _page = 1;
        selectionChanged = true;
      }
    }
    final previous = {...oldWidget.params}..remove('contentBank');
    final next = {...widget.params}..remove('contentBank');
    if (selectionChanged || jsonEncode(previous) != jsonEncode(next)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  void _change(String key, Object? value) {
    setState(() {
      if (value == null || value == '') {
        _selection.remove(key);
      } else {
        _selection[key] = value;
      }
      _page = 1;
    });
    widget.onChanged(jsonEncode(_selection));
    _load();
  }

  Future<void> _load() async {
    if (widget.trainerKey == 'reading-word-columns') {
      _selection = {
        'libraryId': readingContentBankLibraryId,
        'categoryId': _selection['categoryId'],
        'materialIds': <String>[],
        'kind': 'word',
        'locale': 'ru-RU',
      };
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthScope.of(context).trainerContentBankApi.browse(
        trainerKey: widget.trainerKey,
        filters: {
          'params': jsonEncode(widget.params),
          'selectedMaterialIds':
              (_selection['materialIds'] as List? ?? const []).join(','),
          for (final key in ['categoryId', 'kind', 'locale', 'hasImage'])
            if (_selection[key] != null) key: _selection[key],
        },
        query: widget.trainerKey == 'reading-word-columns' ? '' : _search.text,
        page: _page,
        uiLocale: Localizations.localeOf(context).languageCode,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _result = result;
        for (final raw in [
          ...(result['materials'] as List? ?? const []),
          ...(result['selectedMaterials'] as List? ?? const []),
        ]) {
          if (raw is Map && raw['materialId'] is String) {
            _materialTitles[raw['materialId']] =
                raw['title']?.toString().trim().isNotEmpty == true
                ? raw['title'].toString()
                : raw['preview']?.toString() ?? '';
          }
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Widget _filter(String key, String label, List<dynamic> items) =>
      DropdownButtonFormField<String>(
        key: ValueKey('$key:${_selection[key] ?? ''}'),
        initialValue:
            items.any((item) => item is Map && item['id'] == _selection[key])
            ? _selection[key] as String?
            : '',
        decoration: InputDecoration(labelText: label),
        isExpanded: true,
        items: [
          DropdownMenuItem(value: '', child: Text(_copy('Все', 'All', 'الكل'))),
          for (final raw in items)
            if (raw is Map)
              DropdownMenuItem(
                value: raw['id'].toString(),
                child: Text(
                  raw['title'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        ],
        onChanged: (value) => _change(key, value),
      );
  String _copy(String ru, String en, String ar) =>
      switch (Localizations.localeOf(context).languageCode) {
        'en' => en,
        'ar' => ar,
        _ => ru,
      };
  @override
  Widget build(BuildContext context) {
    final selected = (_selection['materialIds'] as List? ?? const [])
        .map((id) => id.toString())
        .toSet();
    final materials = _result?['materials'] as List? ?? const [];
    final total = _result?['total'] as num? ?? 0;
    if (widget.trainerKey == 'reading-word-columns') {
      final categories = (_result?['categories'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      final selectedCategory = categories
          .where((c) => c['id'] == _selection['categoryId'])
          .firstOrNull;
      final topic =
          selectedCategory?['parentId'] ?? _selection['categoryId'] ?? '';
      final roots = categories.where((c) => c['parentId'] == null).toList();
      final leaves = categories.where((c) => c['parentId'] == topic).toList();
      Widget field(
        String label,
        String value,
        List<Map> choices,
        bool required,
      ) => DropdownButtonFormField<String>(
        key: ValueKey('$label:$value'),
        initialValue: choices.any((c) => c['id'] == value) ? value : '',
        decoration: InputDecoration(labelText: label),
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(_copy('Выберите', 'Choose', 'اختر')),
          ),
          for (final c in choices)
            DropdownMenuItem(
              value: c['id'].toString(),
              child: Text(
                c['title'].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        validator: (value) => required && (value == null || value.isEmpty)
            ? _copy(
                'Выберите подтему',
                'Choose a subtopic',
                'اختر موضوعاً فرعياً',
              )
            : null,
        onChanged: choices.isEmpty
            ? null
            : (value) => _change('categoryId', value),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(
            _copy('Тема', 'Topic', 'الموضوع'),
            topic.toString(),
            roots,
            false,
          ),
          const SizedBox(height: 12),
          field(
            _copy('Подтема', 'Subtopic', 'الموضوع الفرعي'),
            selectedCategory?['parentId'] != null
                ? _selection['categoryId'].toString()
                : '',
            leaves,
            true,
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_loading && selectedCategory?['parentId'] != null && total == 0)
            Text(
              _copy(
                'В подтеме нет русских слов.',
                'No Russian words in this subtopic.',
                'لا توجد كلمات روسية في هذا الموضوع الفرعي.',
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _copy(
            'Материалы из банка',
            'Materials from the bank',
            'مواد من المكتبة',
          ),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (selected.isNotEmpty)
          Wrap(
            spacing: 6,
            children: [
              for (final id in selected)
                InputChip(
                  label: Text(
                    _materialTitles[id] ??
                        _copy(
                          'Недоступный материал',
                          'Unavailable material',
                          'مادة غير متاحة',
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () => _change(
                    'materialIds',
                    selected.where((value) => value != id).toList(),
                  ),
                ),
            ],
          ),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: _copy('Поиск', 'Search', 'بحث'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              _page = 1;
              _load();
            });
          },
        ),
        _filter(
          'categoryId',
          _copy('Тема / подтема', 'Topic / subtopic', 'الموضوع'),
          _result?['categories'] as List? ?? const [],
        ),
        DropdownButtonFormField<String>(
          key: ValueKey('kind:${_selection['kind'] ?? ''}'),
          initialValue: _selection['kind'] as String? ?? '',
          decoration: InputDecoration(
            labelText: _copy('Тип материала', 'Material type', 'نوع المادة'),
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(_copy('Все', 'All', 'الكل')),
            ),
            DropdownMenuItem(
              value: 'word',
              child: Text(_copy('Слово', 'Word', 'كلمة')),
            ),
            DropdownMenuItem(
              value: 'phrase',
              child: Text(_copy('Фраза', 'Phrase', 'عبارة')),
            ),
            DropdownMenuItem(
              value: 'text',
              child: Text(_copy('Текст', 'Text', 'نص')),
            ),
          ],
          onChanged: (value) => _change('kind', value),
        ),
        DropdownButtonFormField<String>(
          key: ValueKey('locale:${_selection['locale'] ?? ''}'),
          initialValue: _selection['locale'] as String? ?? '',
          decoration: InputDecoration(
            labelText: _copy(
              'Язык материала',
              'Material language',
              'لغة المادة',
            ),
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(_copy('Все', 'All', 'الكل')),
            ),
            const DropdownMenuItem(value: 'ru-RU', child: Text('Русский')),
            const DropdownMenuItem(value: 'en-US', child: Text('English')),
            const DropdownMenuItem(value: 'ar-XA', child: Text('العربية')),
          ],
          onChanged: (value) => _change('locale', value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_copy('Только с картинкой', 'With an image', 'مع صورة')),
          value: _selection['hasImage'] == true,
          onChanged: (value) => _change('hasImage', value ? true : null),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) TextButton(onPressed: _load, child: Text(_error!)),
        if (!_loading && _error == null && materials.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _copy(
                'Подходящих опубликованных материалов нет.',
                'No matching published materials.',
                'لا توجد مواد منشورة مطابقة.',
              ),
            ),
          ),
        for (final raw in materials)
          if (raw is Map)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                raw['title']?.toString().trim().isNotEmpty == true
                    ? raw['title'].toString()
                    : raw['preview']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${raw['locale']} · ${raw['preview'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              secondary: raw['hasImage'] == true
                  ? const Icon(Icons.image_outlined)
                  : null,
              value: selected.contains(raw['materialId']),
              onChanged: (checked) {
                final next = widget.selectionMode == 'single' && checked == true
                    ? <String>{}
                    : {...selected};
                checked == true
                    ? next.add(raw['materialId'].toString())
                    : next.remove(raw['materialId']);
                _change('materialIds', next.toList());
              },
            ),
        Text(
          _copy(
            selected.isEmpty
                ? 'Выберите хотя бы один материал.'
                : 'Выбрано: ${selected.length}.',
            selected.isEmpty
                ? 'Select at least one material.'
                : 'Selected: ${selected.length}.',
            selected.isEmpty
                ? 'اختر مادة واحدة على الأقل.'
                : 'المحدد: ${selected.length}.',
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _page > 1 && !_loading
                  ? () {
                      _page--;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$_page · $total'),
            IconButton(
              onPressed: _page * 25 < total && !_loading
                  ? () {
                      _page++;
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}
