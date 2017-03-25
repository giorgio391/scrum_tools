import 'package:angular2/core.dart';

import 'package:scrum_tools/src/scrum_service.dart';
import 'package:scrum_tools/src/utils/simple_editor.dart';
import 'package:scrum_tools/src/scrum_stopwatch/scrum_stopwatch.dart';
import 'package:scrum_tools/src/scrum_stopwatch/stopwatch_pipe.dart';
import 'package:scrum_tools/src/web_socket_service.dart';
import 'package:scrum_tools/src/daily/daily_entities.dart';
import 'package:scrum_tools/src/rest_service.dart';

/// This class provides a web component to manage speaking times for a Scrum
/// team members.
///
/// Internally it uses a [ScrumStopwatch] component to depict the stop watch.
/// In addition it handles the lists of people to go and people whose turn has
/// already passed.
///
/// The list of team members is acquired by this component by means of a
/// [ScrumService] whose injection is expected by the constructor
/// [new DailyTimer].
@Component(
    selector: 'daily-timer',
    templateUrl: 'daily_timer.html',
    styleUrls: const ['daily_timer.css'],
    pipes: const [StopwatchPipe],
    directives: const [ScrumStopwatch, SimpleEditor],
    providers: const [RestService, ScrumService, ScrumStopwatch]
)
class DailyTimer implements OnInit {

  // Uncomment the following in the future if the child [ScrumStopwatch] must
  // be injected.

  @ViewChild(ScrumStopwatch)
  ScrumStopwatch scrumStopWatch;

  ScrumService _service;
  DailyEventBus _eventBus;
  RestService _restService;

  DailyTimer(this._restService, this._service, this._eventBus);

  MemberRecord _current;

  /// List of people pending to talk.
  final List<MemberRecord> pending = new List<MemberRecord>();

  /// List of people who has already talked.
  final List<MemberRecord> done = new List<MemberRecord>();

  /// The record that corresponds to the person that are currently allowed
  /// to take the floor.
  MemberRecord get current => _current;

  /// Uses the [ScrumService] to retrieve the team member list and initialize
  /// the component.
  void ngOnInit() {
    _service.config.then((ScrumConfig config) {
      config.teamMemberNames.forEach((String name) =>
          pending.add(new MemberRecord()..name = name));
      shuffle();
    });
  }

  /// Removes [item] from the list of the pending people. If [item] did not
  /// exist within the list, nothing would happen.
  void remove(MemberRecord item) {
    pending.remove(item);
  }

  /// Promote [toPromote] to the top of the pending people list. If [item]
  /// did not exist within the list, nothing would happen.
  void promote(MemberRecord toPromote) {
    if (pending.contains(toPromote)) {
      int index = pending.indexOf(toPromote);
      if (index > 0) {
        pending.insert(0, pending.removeAt(index));
      }
    }
  }

  /// Shuffles the pending people list.
  void shuffle() {
    if (pending.length > 1) pending.shuffle();
  }

  /// Removes [item] from the list of the people already done and move it to
  /// the top of the list of pending people. If [item] did not exit within the
  /// list of people already done, nothing would happen.
  void doReplay(MemberRecord item) {
    if (done.contains(item)) {
      done.remove(item);
      pending.insert(0, item);
    }
  }

  /// This is the method hooked to the _next_ event of the inner
  /// [ScrumStopwatch]. [scrumStopwatch] is the [ScrumStopwatch] who fires
  /// the event.
  void onNext(ScrumStopwatch scrumStopwatch) {
    if (_current != null) {
      Duration d = scrumStopwatch.unitDuration;
      _current.duration = d;
      done.insert(0, _current);
    }
    _current = pending.length > 0 ? pending.removeAt(0) : null;
    _eventBus.sendTeamMemberMessage(_current.name);
  }

  /// This is the method hooked to the _start_ event of the inner
  /// [ScrumStopwatch].
  void onStart() {
    _current = pending.length > 0 ? pending.removeAt(0) : null;
  }

  /// This is the method hooked to the _reset_ event of the inner
  /// [ScrumStopwatch].
  void onReset() {
    while (done.length > 0) {
      MemberRecord item = done.removeAt(0);
      item.duration = null;
      pending.insert(0, item);
    }
  }

  /// This method is provided to the inner [ScrumStopwatch] to let it grab
  /// the offset upon _next_ events. See [ScrumStopwatch.startOffsetProvider].
  Duration startOffset() {
    return _current != null ? _current.duration : null;
  }

  /// Adds a new person (by the name) to the bottom of the list of pending
  /// people.
  void addName(String name) {
    if (name != null) {
      pending.add(new MemberRecord()..name = name);
    }
  }

  void save() {
    TimeReport report = new TimeReport(
        new DateTime.now(),
        scrumStopWatch.grossDuration,
            () {
          if (done != null && done.isNotEmpty) {
            return new List<TimeReportEntry>.from(
                done.map((MemberRecord record) {
                  return new TimeReportEntry()
                    ..teamMemberCode = record.name
                    ..netDuration = record.duration;
                }));
          }
          return null;
        }()
    );
    _restService.saveTimeReport(report);
  }
}

/// The objects of this class represents a team member, holding the name and
/// the time already spent speaking as a [Duration]. It is used as items in the
/// lists of _pending_ and _done_.
class MemberRecord {
  /// Name of the person represented by this object.
  String name;

  /// Time already spent speaking.
  Duration duration;
}