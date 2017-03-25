import 'package:angular2/core.dart';

import 'package:angular2_components/angular2_components.dart';

@Component(selector: 'dailyX',
    template: '''
      <div style="margin: 10px; height: 99%;">
        <glyph icon="favorite"></glyph>
        <material-fab mini raised>
          <glyph icon="check"></glyph>
        </material-fab>
      </div>
    ''',
    directives: const [materialDirectives],
    providers: const [materialProviders]
)
class DailyX {

  final String name = 'DailyX app';

  DailyX();

}
