import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/places_api.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

const _debounceMs = 400;
const _minQueryLength = 2;

class PlaceAutocompleteField extends StatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.placesApi,
    required this.locale,
    required this.label,
    this.initialDisplayLabel = '',
    this.initialMapboxId,
    this.onChanged,
    this.optional = false,
  });

  final PlacesApi placesApi;
  final String locale;
  final String label;
  final String initialDisplayLabel;
  final String? initialMapboxId;
  final ValueChanged<PlaceCitySelection?>? onChanged;
  final bool optional;

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  String? _hint;
  bool _isResolving = false;
  String? _mapboxId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDisplayLabel);
    _mapboxId = widget.initialMapboxId;
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant PlaceAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDisplayLabel != widget.initialDisplayLabel &&
        widget.initialDisplayLabel != _controller.text.trim()) {
      _controller.text = widget.initialDisplayLabel;
      _mapboxId = widget.initialMapboxId;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final query = _controller.text.trim();
    if (_mapboxId != null && query != widget.initialDisplayLabel.trim()) {
      _mapboxId = null;
      widget.onChanged?.call(null);
    }

    _debounce?.cancel();
    if (query.length < _minQueryLength) {
      setState(() {
        _suggestions = const [];
        _hint = null;
      });
      if (query.isEmpty) {
        widget.onChanged?.call(
          widget.optional ? const PlaceCitySelection(displayLabel: '', mapboxId: '') : null,
        );
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final suggestions = await widget.placesApi.suggest(
        locale: widget.locale,
        mode: 'city',
        query: query,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _hint = suggestions.isEmpty ? null : null;
      });
    } on PlacesApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const [];
        _hint = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const [];
        _hint = context.l10n.placesAutocompleteUnavailable;
      });
    }
  }

  Future<void> _chooseSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _suggestions = const [];
      _hint = null;
      _isResolving = true;
    });

    try {
      final resolved = await widget.placesApi.resolve(
        locale: widget.locale,
        mode: 'city',
        mapboxId: suggestion.mapboxId,
      );
      if (!mounted) {
        return;
      }

      final displayLabel =
          resolved.city?.trim().isNotEmpty == true
              ? resolved.city!.trim()
              : resolved.displayLabel.split(',').first.trim().isNotEmpty
              ? resolved.displayLabel.split(',').first.trim()
              : suggestion.shortLabel;

      final selection = PlaceCitySelection(
        displayLabel: displayLabel,
        mapboxId: resolved.mapboxId,
      );

      setState(() {
        _mapboxId = selection.mapboxId;
        _controller.text = selection.displayLabel;
        _isResolving = false;
      });
      widget.onChanged?.call(selection);
    } on PlacesApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mapboxId = null;
        _hint = error.message;
        _isResolving = false;
      });
      widget.onChanged?.call(null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mapboxId = null;
        _hint = context.l10n.placesAutocompleteInvalidSelection;
        _isResolving = false;
      });
      widget.onChanged?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeskTextField(
          controller: _controller,
          label: widget.label,
          labelAsPlaceholder: true,
          textInputAction: TextInputAction.next,
          readOnly: _isResolving,
        ),
        if (_hint != null) ...[
          const SizedBox(height: 6),
          Text(
            _hint!,
            style: GoogleFonts.onest(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ParentColors.inkMuted,
              height: 1.35,
            ),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 2,
            color: ParentColors.surface,
            borderRadius: BorderRadius.circular(DeskTextField.fieldRadius),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: ParentColors.line),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return InkWell(
                  onTap: () => _chooseSuggestion(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      suggestion.label,
                      style: GoogleFonts.onest(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ParentColors.ink,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (widget.optional && _controller.text.trim().isEmpty && _mapboxId == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.notSpecifiedLabel,
              style: GoogleFonts.onest(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ParentColors.inkMuted,
              ),
            ),
          ),
      ],
    );
  }
}
