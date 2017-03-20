import 'dart:html';
import 'package:angular2/core.dart';

/// Simple editor class to provide a web component to edit a string value.
/// It also supplies a button to commit changes.
@Component(selector: 'simple-editor',
    template: '''
    <div class="simple_editor">
      <input (keyup.enter)="keyUp(\$event)" (blur)="commit()" [(ngModel)]="value" placeholder="{{placeHolder}}" />
      <button (click)="commit()" title="Commit current value.">
        <i class="fa fa-check" aria-hidden="true"></i>
        <i class="btn-text">Commit</i>
      </button>
    </div>
    ''',
    styles: const [
      '.simple_editor { '
          'width: 100%; '
          'margin: 10px 0px 10px 0px; '
          'color: #888; '
          'display: -webkit-box;'
          'display: -moz-box;'
          'display: -ms-flexbox;'
          'display: -webkit-flex;'
          'display: flex;'
          'border: 1px solid;'
          'color: #888;'
          'padding-left: 5px;'
          'height: 30px;'
          'box-shadow: 5px 5px 10px 1px rgba(80, 80, 80, 0.50);'
          '} '
          '.simple_editor input {'
          'flex: 1 1;'
          'border: 0px;'
          '}'
          '.simple_editor button {'
          'color: #FFF;'
          'border: 0px;'
          'background-color: #00B388;'
          'cursor: pointer;'
          'height: 30px;'
          'font-size: 14px;'
          'flex: 0 0 30px;'
          '}'
          '.simple_editor button:hover {'
          'font-size: 16px;'
          '}'
          '.simple_editor button:active {'
          'font-size: 12px;'
          '}'
          '.simple_editor button:focus {'
          'outline: 0;'
          '}'
          '.simple_editor button::-moz-focus-inner {'
          'border: 0;'
          '}'
          '.simple_editor input:focus {'
          'outline: 0;'
          '}'
          '.simple_editor input::-moz-focus-inner {'
          'border: 0;'
          '}'
          '.simple_editor .btn-text {display: none;}'
    ]
)
class SimpleEditor {

  /// Placeholder for the HTML input.
  @Input()
  String placeHolder;

  /// Emits a event with the edited string when committed.
  @Output()
  final EventEmitter<String> commitValue = new EventEmitter<String>(false);

  /// Edited value.
  String value;

  /// Method to perform the commit. It emits a event this the value being edited.
  void commit() {
    commitValue.add(value);
    value = null;
  }

  void keyUp(KeyboardEvent event) {
    if (event.which == 13) commit();
  }

}