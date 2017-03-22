import 'package:mailer/mailer.dart';

void main(List<String> args) {
  SmtpOptions options = new SmtpOptions()
    ..hostName = 'posteio.emergya.com'
    ..username = 'team-green@servicios.emergya.com'
    ..password = 'j43vDvgT6g'
    ..secured = true;
  var emailTransport = new SmtpTransport(options);

  var envelope = new Envelope()
    ..from = 'team-green@servicios.emergya.com'
    ..recipients.add('jmurcia@emergya.com')
    ..subject = 'Testing to mail from Dart.'
    ..text = 'This is a cool email message. Whats up?'
    ..html = '<h1>Test</h1><p>Hey!</p>';

  // Email it.
  emailTransport.send(envelope)
      .then((envelope) => print('Email sent!'))
      .catchError((e) => print('Error occurred: $e'));

}