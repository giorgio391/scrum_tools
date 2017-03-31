import 'dart:async';
import 'package:mailer/mailer.dart';

import 'package:scrum_tools/src/utils/helpers.dart';
import 'package:scrum_tools/src/utils/command_line/config.dart';

void main(List<String> args) {

  loadConfig().then((_) {
    Mailer mailer = new Mailer.fromMap({
      'host': 'posteio.emergya.com',
      'user': 'team-green@servicios.emergya.com',
      'pass': 'mailer-1',
      'secured': true,
      'from_name': 'PSNow dev team',
      'recipients': 'jmurcia@emergya.com'
    });

    mailer.sendHtml('Emailer test', '<h1>Test</h1><p>Hey!</p>').then((envelope) =>
        print('Email sent!'))
        .catchError((e) => print('Error occurred: $e'));
    ;
  });

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
      if (map['recipients'] is String)
        _recipients = (map['recipients'] as String).split(_splitRegExp);
      else if (map['recipients'] is Iterable<String>)
        _recipients = new List.from(map['recipients']);
    }
    if (map['cc_recipients'] != null) {
      if (map['cc_recipients'] is String)
        _ccRecipients = (map['cc_recipients'] as String).split(_splitRegExp);
      else if (map['cc_recipients'] is Iterable<String>)
        _ccRecipients = new List.from(map['cc_recipients']);
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