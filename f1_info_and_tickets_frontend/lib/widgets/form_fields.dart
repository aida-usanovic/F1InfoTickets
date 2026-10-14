import 'package:flutter/material.dart';

import '../core/formatters.dart';

/// Date input with a date picker; the validation message is shown under the field.
class DateFormField extends FormField<DateTime> {
  DateFormField({
    super.key,
    required String label,
    super.initialValue,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialPickerDate,
    String? forceErrorText,
    super.validator,
    ValueChanged<DateTime>? onChanged,
  }) : super(
         builder: (state) {
           Future<void> pick() async {
             final picked = await showDatePicker(
               context: state.context,
               initialDate: state.value ?? initialPickerDate ?? lastDate,
               firstDate: firstDate,
               lastDate: lastDate,
               helpText: label,
             );
             if (picked != null) {
               state.didChange(picked);
               onChanged?.call(picked);
             }
           }

           return InkWell(
             onTap: pick,
             borderRadius: BorderRadius.circular(10),
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 prefixIcon: const Icon(Icons.calendar_month_outlined),
                 suffixIcon: const Icon(Icons.arrow_drop_down),
                 errorText: forceErrorText ?? state.errorText,
               ),
               isEmpty: state.value == null,
               child: Text(state.value == null ? '' : formatDate(state.value)),
             ),
           );
         },
       );
}

/// Date and time input (date picker followed by a time picker), in local time.
class DateTimeFormField extends FormField<DateTime> {
  DateTimeFormField({
    super.key,
    required String label,
    super.initialValue,
    required DateTime firstDate,
    required DateTime lastDate,
    String? forceErrorText,
    super.validator,
    ValueChanged<DateTime>? onChanged,
  }) : super(
         builder: (state) {
           Future<void> pick() async {
             final current = state.value;
             final date = await showDatePicker(
               context: state.context,
               initialDate: current ?? DateTime.now(),
               firstDate: firstDate,
               lastDate: lastDate,
               helpText: label,
             );
             if (date == null || !state.mounted) return;
             final time = await showTimePicker(
               context: state.context,
               initialTime: current == null ? const TimeOfDay(hour: 15, minute: 0) : TimeOfDay.fromDateTime(current),
               helpText: 'Start time',
             );
             if (time == null) return;
             final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
             state.didChange(picked);
             onChanged?.call(picked);
           }

           return InkWell(
             onTap: pick,
             borderRadius: BorderRadius.circular(10),
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 prefixIcon: const Icon(Icons.event_outlined),
                 suffixIcon: const Icon(Icons.arrow_drop_down),
                 errorText: forceErrorText ?? state.errorText,
               ),
               isEmpty: state.value == null,
               child: Text(state.value == null ? '' : formatDateTime(state.value)),
             ),
           );
         },
       );
}

/// Password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? forceErrorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.forceErrorText,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      forceErrorText: widget.forceErrorText,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
