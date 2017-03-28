import 'dart:async';
import 'package:mailer/mailer.dart';

import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';

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

class Message extends Envelope {
  Message(String subject, String html) {
    super.subject = subject;
    super.html = html;
  }
}

class Mailer {

  static final RegExp _splitRegExp = new RegExp(r'\s*,\s*');

  SmtpTransport _transport;
  String _from, _fromName;
  List<String> _recipients;
  List<String> _ccRecipients;

  Mailer.fromMap(Map<String, dynamic> map) {
    SmtpOptions options = new SmtpOptions()
      ..hostName = map['host']
      ..username = map['user']
      ..password = map['pass'] != null ? getPass(map['pass']) : null
      ..name = map['name']
      ..secured = map['secured'];
    _transport = new SmtpTransport(options);
    _from = map['from'] == null ? map['user'] : map['from'];
    if (map['from_name'] != null) _fromName = map['from_name'];
    if (map['recipients'] != null) {
      _recipients = (map['recipients'] as String).split(_splitRegExp);
    }
    if (map['cc_recipients'] != null) {
      _ccRecipients = (map['cc_recipients'] as String).split(_splitRegExp);
    }
  }

  Future send(Message message) {
    if (!hasValue(message.fromName) && hasValue(_fromName))
      message.fromName = _fromName;
    if (hasValue(_recipients) && !hasValue(message.recipients)) {
      message.recipients.addAll(_recipients);
    }
    if (hasValue(_ccRecipients) && !hasValue(message.ccRecipients)) {
      message.ccRecipients.addAll(_ccRecipients);
    }
    if (hasValue(_from)) message.from = _from;
    return _transport.send(message);
  }

  Future sendHtml(String subject, String html) {
    return send(new Message(subject, html));
  }
}