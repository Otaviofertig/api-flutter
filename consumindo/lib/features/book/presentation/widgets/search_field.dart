import 'package:flutter/material.dart';

/// Campo de busca do app.
///
/// O debounce vive no controller, não aqui: este widget só reporta o texto.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
    this.hintText = 'Busque por título, autor ou ISBN',
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;
  final String hintText;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final bool hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    widget.onCleared();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.sentences,
      onChanged: _onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Limpar busca',
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
