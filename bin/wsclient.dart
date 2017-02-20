import 'dart:io';

void main(List<String> args) {
  WebSocket.connect('ws://localhost:3000/ws').then((WebSocket wSocket) {
    wSocket.listen((dynamic data) {
      print('Data received: ${data}');
      //wSocket.add('close');
    });
    wSocket.add('ping');
    wSocket.add('group: 23');

    wSocket.add('message: {"ref": 2333}');
  });
  /*
  NetworkInterface.list(type: InternetAddressType.IP_V4).then((List<NetworkInterface> list) {
    print(list.first.addresses.first.address);
  });
  */
}