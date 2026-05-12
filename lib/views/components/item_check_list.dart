import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme.dart';

/// A rich checklist item that supports bold text via **bold** markdown syntax.
class ItemCheckList extends StatefulWidget {
  final String title;
  final List<String>? list;

  const ItemCheckList({super.key, required this.title, this.list});

  @override
  State<ItemCheckList> createState() => _ItemCheckListState();
}

class _ItemCheckListState extends State<ItemCheckList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BoldableText(text: widget.title),
          if (widget.list != null) ...[
            SizedBox(height: 12.h),
            ...widget.list!.map((item) => _CheckItem(text: item)),
          ],
        ],
      ),
    );
  }
}

class _CheckItem extends StatefulWidget {
  final String text;

  const _CheckItem({required this.text});

  @override
  State<_CheckItem> createState() => _CheckItemState();
}

class _CheckItemState extends State<_CheckItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _checked = !_checked),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _checked,
              onChanged: (v) => setState(() => _checked = v ?? false),
              activeColor: AppTheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: BoldableText(text: widget.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders text with **bold** segments parsed from the string.
class BoldableText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const BoldableText({super.key, required this.text, this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ??
        TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface, height: 1.5);

    final parts = text.split('**');
    if (parts.length == 1) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd
            ? style.copyWith(fontWeight: FontWeight.w700)
            : style,
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}
