import 'dart:convert' show HtmlEscape;

import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rally/rally_entities.dart';
import 'package:scrum_tools/src/utils/command_line/formatter.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

class TeamMemberReportTemplate {

  Map<String, dynamic> ctx;
  StringBuffer _buffer;
  HtmlEscape htmlEscape = new HtmlEscape();
  int _colspan;
  Map<String, RDWorkItem> _workItems;

  TeamMemberReportTemplate(this.ctx) {
    _workItems = ctx['work-items'];
  }

  String html(String raw) => htmlEscape.convert(raw);

  void _innerCtx(Map<String, dynamic> innerCtx, call()) {
    Map<String, dynamic> initialCtx = ctx;
    try {
      ctx = innerCtx;
      call();
    } finally {
      ctx = initialCtx;
    }
  }

  String subject(String teamMemberCode) =>
      '[PSNow] Daily report [${teamMemberCode}] >> ${formatDate(ctx['date'])}>';

  void _buildTable(String title, bodyBuilder(),
      {int colspan: null, bool border: false, highlightTitle: true}) {
    _buffer.write('<table style="font-family: Helvetica, Arial, Sans-Serif; '
        '${border ? "border: 1px solid lightgrey;" : ""} '
        'padding: 5px;" width="100%">');
    _buffer.write(r'<thead>');
    if (highlightTitle) {
      _buffer.write(
          r'<tr style="text-align: center; background: black; color: white; '
          r'font-weight: bold;">');
    } else {
      _buffer.write(r'<tr style="font-size: larger;">');
    }
    _buffer.write('<th ${colspan != null ? "colspan='${colspan}'" :
    ""} style="padding: 5px;">');
    _buffer.writeln(title);
    _buffer.writeln(r'</th></tr></thead><tbody>');

    int initialColspan = _colspan;

    try {
      _colspan = colspan;
      bodyBuilder();
    } finally {
      _colspan = initialColspan;
    }

    _buffer.writeln(r'</tbody></table>');
  }

  void _buildColumnHeaders(List<Map<String, dynamic>> columns) {
    _buffer.writeln(
        r'<tr style="color: white; font-weight: bold; font-size: smaller;">');
    columns.forEach((Map<String, dynamic> map) {
      String align = map['align'] ?? 'left';
      _buffer.writeln(
          '<td valign="middle" style="background: dimgrey; '
              'padding: 6px; text-align: ${align};" '
              '${map['nowrap'] == true ? "nowrap " : ""}'
              '${map['colspan'] != null ? "colspan='${map['colspan']}' " : ""}'
              '${map['width'] != null ? "width='${map['width']}' " : ""}'
              'title="${map['title']}">');
      _buffer.writeln(html(map['caption']));
      _buffer.writeln(r'</td>');
    });
    _buffer.writeln(r'</tr>');
  }

  void _buildRow(List<Map<String, dynamic>> columns, [bool even = false]) {
    _buffer.writeln(even ? r'<tr style="background: #ECECEC;">' : '<tr>');
    columns.forEach((Map<String, dynamic> map) {
      String align = map['align'] ?? 'left';
      _buffer.writeln(
          '<td valign="top" style="padding: 5px; text-align: ${align};'
              '${hasValue(map['style']) ? map['style'] : ''}" '
              '${map['nowrap'] == true ? "nowrap " : ""}'
              '${map['colspan'] != null ? "colspan='${map['colspan']}' " : ""}'
              '${map['width'] != null ? "width='${map['width']}' " : ""}'
              'title="${map['title']}">');
      if (map['escape'] == false)
        _buffer.writeln(map['content']);
      else
        _buffer.writeln(html(map['content']));
      _buffer.writeln(r'</td>');
    });
    _buffer.writeln(r'</tr>');
  }

  String buildText(String teamMemberCode) {
    String title = html(
        ctx['previous-date'] != null ?
        "Daily report [${teamMemberCode}] ${formatDate(
            ctx['previous-date'])} >> ${formatDate(ctx['date'])}" :
        "Daily report [${teamMemberCode}] >> ${formatDate(ctx['date'])}"
    );

    _buffer = new StringBuffer();

    _buildTable(title, () =>
        _innerCtx(ctx[r'team-members-map'][teamMemberCode], _buildBody),
        border: true, highlightTitle: false);

    return _buffer.toString();
  }


  void _buildBody() {
    _buffer.writeln(r'<tr><td style="text-align: center;">');
    _buildPlan();
    _buffer.writeln(r'</td></tr>');
    _buffer.writeln(r'<tr><td style="text-align: center;">');
    _buildReport();
    _buffer.writeln(r'</td></tr>');
  }

  void _buildPlan() {
    var headers = [
      {'caption': 'Process', 'title': 'Process associated to the entry.'},
      {
        'caption': 'Description',
        'title': 'Description of the activity.',
        'colspan': 2
      },
      {
        'caption': 'Planned Status',
        'title': 'Planned final status.',
        'nowrap': true
      }
    ];
    Iterable<DailyEntry> entries = ctx['plan'];
    _buildTable('PLAN', () {
      if (!hasValue(entries)) {
        _buffer.writeln(
            '<tr></tr><td style="text-align: center;" colspan="${_colspan}">-&nbsp;NONE&nbsp;-</td></tr>');
      } else {
        _buildColumnHeaders(headers);
        bool even = false;
        entries.forEach((DailyEntry entry) {
          _buildRow(hasValue(entry.workItemCode) ? [
            {'content': entry.process.toString(), 'title': headers[0]['title']},
            {
              'content': _workItemLink(entry.workItemCode),
              'title': headers[1]['title'],
              'escape': false
            },
            {
              'content': _entryDescText(entry),
              'title': headers[1]['title'],
              'escape': false,
              'width': '100%'
            },
            {
              'content': entry.status.toString(),
              'title': headers[2]['title'],
              'align': 'center'
            },
          ] :
          [{'content': entry.process.toString(), 'title': headers[0]['title']},
          {
            'content': _entryDescText(entry),
            'title': headers[1]['title'],
            'colspan': 2,
            'escape': false,
            'width': '100%'
          },
          {
            'content': entry.status.toString(),
            'title': headers[2]['title'],
            'align': 'center'
          },
          ], even);
          even = !even;
        });
      }
    }, colspan: headers.length + 1);
  }

  void _buildReport() {
    var headers = [
      {'caption': 'Process', 'title': 'Process associated to the entry.'},
      {
        'caption': 'Description',
        'title': 'Description of the activity.',
        'colspan': 2
      },
      {
        'caption': 'Previous Plan',
        'title': 'Previously planned status.',
        'nowrap': true
      },
      {
        'caption': 'Reported Status',
        'title': 'Most recently reported status.',
        'nowrap': true
      },
      {
        'caption': 'Hours',
        'title': 'Reported spent hours.',
        'align': 'center'
      }
    ];
    Iterable<DailyEntry> reported = ctx['reported'];
    Iterable<DailyEntry> unreported = ctx['unreported'];

    _buildTable("REPORTED:: Hours: ${ctx[r'hours-a'] +
        ctx[r'hours-b']} [A: ${ctx[r'hours-a']} / B: ${ctx[r'hours-b']}]", () {
      if (!hasValue(reported) && !hasValue(unreported)) {
        _buffer.writeln(
            '<tr></tr><td style="text-align: center;" colspan="${_colspan}">-&nbsp;NONE&nbsp;REPORTED&nbsp;-</td></tr>');
      } else {
        Function myRow = (DailyEntry entry, Status prevPlanStatus,
            Status status,
            double hours, bool even) {
          _buildRow(hasValue(entry.workItemCode) ? [
            {
              'content': entry.process.toString(),
              'title': headers[0]['title']
            },
            {
              'content': _workItemLink(entry.workItemCode),
              'title': headers[1]['title'],
              'escape': false
            },
            {
              'content': _entryDescText(entry),
              'title': headers[1]['title'],
              'escape': false,
              'width': '100%'
            },
            {
              'content': prevPlanStatus == null ? '-' : prevPlanStatus
                  .toString(),
              'title': headers[2]['title'],
              'align': 'center'
            },
            {
              'content': status == null ? '-' : status.toString(),
              'title': headers[3]['title'],
              'align': 'center',
              'style': _style(prevPlanStatus, status)
            },
            {
              'content': hours == null ? '-' : formatDouble(hours),
              'title': headers[4]['title'],
              'align': 'right'
            }
          ] :
          [
            {
              'content': entry.process.toString(),
              'title': headers[0]['title']
            },
            {
              'content': _entryDescText(entry),
              'title': headers[1]['title'],
              'escape': false,
              'width': '100%',
              'colspan': 2
            },
            {
              'content': prevPlanStatus == null ? '-' : prevPlanStatus
                  .toString(),
              'title': headers[2]['title'],
              'align': 'center'
            },
            {
              'content': status == null ? '-' : status.toString(),
              'title': headers[3]['title'],
              'align': 'center',
              'style': _style(prevPlanStatus, status)
            },
            {
              'content': hours == null ? '-' : formatDouble(hours),
              'title': headers[4]['title'],
              'align': 'right'
            }
          ], even);
        };
        _buildColumnHeaders(headers);
        bool even = false;
        if (hasValue(reported)) {
          reported.forEach((DailyEntry entry) {
            String trackKey = trackingKey(entry);
            Status prevPlanStatus = ctx[r'previous-plan'] != null &&
                ctx[r'previous-plan'][trackKey] != null ?
            ctx[r'previous-plan'][trackKey] : null;
            myRow(entry, prevPlanStatus, entry.status, entry.hours, even);
            even = !even;
          });
        }
        if (hasValue(unreported)) {
          unreported.forEach((DailyEntry entry) {
            myRow(entry, entry.status, null, null, even);
            even = !even;
          });
        }
      }
    }, colspan: headers.length + 1);


    _buffer.writeln('''<br/>
<div style="display: inline-block; margin: 5px; padding: 5px; font-weight: bold; color: white; background: green;">Status as planned</div>
<div style="display: inline-block; margin: 5px; padding: 5px; font-weight: bold; color: black; background: LightGreen;">Status beyond the plan</div>
<div style="display: inline-block; margin: 5px; padding: 5px; font-weight: bold; color: white; background: red;">Status below the plan</div>
<div style="display: inline-block; margin: 5px; padding: 5px; font-weight: bold; color: black; background: gold;">Not previously planned</div>
        ''');
  }

  String _style(Status prevPlanStatus, Status status) {
    if (prevPlanStatus == null && status == null) return r'';
    if (prevPlanStatus == null && status != null)
      return r'font-weight: bold; color: black; background: gold;';
    if (prevPlanStatus != null && status == null)
      return r'font-weight: bold; color: white; background: red;';
    if (prevPlanStatus > status)
      return r'font-weight: bold; color: white; background: red;';
    if (prevPlanStatus == status)
      return r'font-weight: bold; color: white; background: green;';
    if (prevPlanStatus < status)
      return r'font-weight: bold; color: black; background: LightGreen;';
    return r'';
  }

  String _workItemLink(String workItemCode) {
    String style = _maxPriority(_workItems[workItemCode])
        ? 'color: red; font-weight: bold;'
        : '';
    return '<a href="https://rally1.rallydev.com/#/55308115013d/search?keywords=${workItemCode}" '
        'target="_blank" style="text-decoration: none; ${style}">${workItemCode}</a>';
  }

  String _entryDescText(DailyEntry entry) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(r'<div style="display: block;">');
    if (hasValue(entry.workItemCode)) {
      buffer.write(r'<div>');
      buffer.write(html(_workItems[entry.workItemCode].name));
      buffer.write(r'</div>');
    }
    if (hasValue(entry.statement)) {
      buffer.write(r'<div style="color: blue;">');
      buffer.write(html(entry.statement));
      buffer.write(r'</div>');
    }
    if (hasValue(entry.notes)) {
      buffer.write(r'<div style="color: grey;">');
      buffer.write(html(entry.notes));
      buffer.write(r'</div>');
    }
    buffer.write(r'</div>');

    return buffer.toString();
  }

}

bool _maxPriority(RDWorkItem workItem) =>
    (workItem is RDDefect && workItem.priority == RDPriority.MAX_PRIORITY) ||
        (workItem is RDHierarchicalRequirement &&
            workItem.risk == RDRisk.MAX_RISK);
