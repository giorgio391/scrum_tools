import 'dart:html';
import 'package:angular2/common.dart';
import 'package:angular2/core.dart';
import 'package:scrum_tools/src/scrum_service.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/utils/helpers.dart';

@Component(selector: 'daily-form',
    templateUrl: 'daily_form.html',
    styleUrls: const['daily_form.css'],
    directives: const[PatternValidator]
)
class DailyForm {

  static final RegExp _defectRegExp = new RegExp(r'^DE[0-9][0-9][0-9][0-9]$');
  static final RegExp _usRegExp = new RegExp(
      r'^US[0-9][0-9][0-9][0-9][0-9]$');
  static final RegExp _3DRegExp = new RegExp(r'^[0-9][0-9][0-9]$');
  static final RegExp _4DRegExp = new RegExp(r'^[0-9][0-9][0-9][0-9]$');
  static final RegExp _5DRegExp = new RegExp(r'^[0-9][0-9][0-9][0-9][0-9]$');

  @Output()
  final EventEmitter<String> workItemCodeChange = new EventEmitter<String>(
      false);

  @Output()
  final EventEmitter<ChangeRecord<DailyEntry>> onEntryEdited = new EventEmitter<
      ChangeRecord<DailyEntry>>(false);

  @Output()
  final EventEmitter<String> onStopwatchRequest = new EventEmitter<String>(
      false);

  DailyEntry _beingEdited;
  DailyEntry _model;

  _EnvironmentsHelper _envHelper = new _EnvironmentsHelper();

  _EnvironmentsHelper get env => _envHelper;

  List<String> _teamMembers;

  List<String> get teamMembers => _teamMembers;

  DailyEntry get model => _model;

  DailyEntry _lastEditing;

  @Input()
  void set model(DailyEntry modelToEdit) {
    _model =
    modelToEdit != null ? new DailyEntry.clone(modelToEdit) :
    (_lastEditing != null ? _lastEditing : new DailyEntry());
    _beingEdited = modelToEdit;
    _envHelper.model = _model;
  }

  String get teamMemberCode => model != null ? model.teamMemberCode : null;

  @Input()
  void set teamMemberCode(String code) {
    if (code == null || teamMembers.contains(code)) {
      model.teamMemberCode = code;
    } else {
      model.teamMemberCode = null;
    }
  }

  DailyForm(ScrumService service) {
    service.config.then((ScrumConfig config) {
      _teamMembers = config.teamMemberNames;
    });
    model = null;
  }

  void wiKeyUp(KeyboardEvent event) {
    if (event.which == 13) checkWiCode();
  }

  void nextTeamMember() {
    onStopwatchRequest.add('next');
  }

  void checkWiCode() {
    if (model.workItemCode != null) {
      model.workItemCode = model.workItemCode.trim().toUpperCase();
      if (_3DRegExp.hasMatch(model.workItemCode)) {
        model.workItemCode = "US19${model.workItemCode}";
      } else if (_4DRegExp.hasMatch(model.workItemCode)) {
        model.workItemCode = "DE${model.workItemCode}";
      } else if (_5DRegExp.hasMatch(model.workItemCode)) {
        model.workItemCode = "US${model.workItemCode}";
      }
      _triggerWi(_defectRegExp.hasMatch(model.workItemCode) ||
          _usRegExp.hasMatch(model.workItemCode) ? model.workItemCode : null);
    } else {
      _triggerWi(null);
    }
  }

  void _triggerWi(String wiCode) {
    workItemCodeChange.add(wiCode);
  }

  void onSubmit() {
    ChangeRecord<DailyEntry> changeRecord = new ChangeRecord<DailyEntry>(
        _beingEdited, _model);
    _lastEditing = changeRecord.newValue != null ? new DailyEntry() : null;
    if (_lastEditing != null) {
      _lastEditing.teamMemberCode = changeRecord.newValue.teamMemberCode;
      _lastEditing.process= changeRecord.newValue.process;
      _lastEditing.scope = changeRecord.newValue.scope;
    }
    model = null;
    onEntryEdited.add(changeRecord);
  }

  void cancel() {
    ChangeRecord<DailyEntry> changeRecord = new ChangeRecord<DailyEntry>(
        _beingEdited, null);
    onEntryEdited.add(changeRecord);
    model = null;
  }

  bool get pastScope =>
      model == null || model.scope == null || model.scope == Scope.PAST;

  bool get editing => _beingEdited != null;

  List<Scope> get scopes => Scope.VALUES;

  List<Process> get processes => Process.VALUES;

  List<Environment> get environments => Environment.VALUES;

  List<Status> get statuses => Status.VALUES;

  void normalizeHours(double value) {
    if (_model != null) {
      _model.hours = _normalizeHours(value);
    }
  }

  double _normalizeHours(double value) {
    if (value == null) return null;
    double newValue = value.abs();
    double floor = newValue.floorToDouble();
    if (floor < newValue) {
      double decimal = newValue - floor;
      if (decimal <= 0.125) {
        newValue = floor;
      } else if (decimal > 0.125 && decimal <= 0.375) {
        newValue = floor + 0.25;
      } else if (decimal > 0.375 && decimal <= 0.625) {
        newValue = floor + 0.5;
      } else if (decimal > 0.625 && decimal <= 0.875) {
        newValue = floor + 0.75;
      } else {
        newValue = floor + 1.0;
      }
    }
    return newValue;
  }

}

class _EnvironmentsHelper {

  DailyEntry _model;

  DailyEntry get model => _model;

  void set model(DailyEntry model) {
    _model = model;
    _qa = false;
    _uat = false;
    _pre = false;
    _pro = false;
    if (_model.environments != null && _model.environments.isNotEmpty) {
      _qa = _model.environments.contains(Environment.QA);
      _uat = _model.environments.contains(Environment.UAT);
      _pre = _model.environments.contains(Environment.PRE);
      _pro = _model.environments.contains(Environment.PRO);
    }
  }

  bool _qa;
  bool _uat;
  bool _pre;
  bool _pro;

  bool get QA => _qa;

  bool get UAT => _uat;

  bool get PRE => _pre;

  bool get PRO => _pro;

  void set QA(bool b) {
    _qa = b;
    _updateList();
  }

  void set UAT(bool b) {
    _uat = b;
    _updateList();
  }

  void set PRE(bool b) {
    _pre = b;
    _updateList();
  }

  void set PRO(bool b) {
    _pro = b;
    _updateList();
  }

  _updateList() {
    if (_qa || _uat || _pre || _pro) {
      if (_model.environments == null) {
        _model.environments = [];
      }
      _model.environments.remove(Environment.QA);
      _model.environments.remove(Environment.UAT);
      _model.environments.remove(Environment.PRE);
      _model.environments.remove(Environment.PRO);
      if (_qa) _model.environments.add(Environment.QA);
      if (_uat) _model.environments.add(Environment.UAT);
      if (_pre) _model.environments.add(Environment.PRE);
      if (_pro) _model.environments.add(Environment.PRO);
    } else {
      if (_model.environments != null) {
        _model.environments.remove(Environment.QA);
        _model.environments.remove(Environment.UAT);
        _model.environments.remove(Environment.PRE);
        _model.environments.remove(Environment.PRO);
      }
    }
  }

}