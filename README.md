# @capgo/capacitor-mqtt

<a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin_mqtt"> ➡️ Get Instant updates for your App with Capgo</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin_mqtt"> Missing a feature? We'll build the plugin for you 💪</a></h2>
</div>

![NPM Version](https://img.shields.io/npm/v/%40capgo%2Fcapacitor-mqtt)
![NPM Downloads](https://img.shields.io/npm/dy/%40capgo%2Fcapacitor-mqtt)
![GitHub Repo stars](https://img.shields.io/github/stars/Cap-go/capacitor-mqtt)
![GitHub License](https://img.shields.io/github/license/Cap-go/capacitor-mqtt)
![Maintenance](https://img.shields.io/maintenance/yes/2025)

<p>
  Capacitor plugin for MQTT connectivity on Android and iOS using the Eclipse Paho MQTT library.
</p>

## Why MQTT?

MQTT (Message Queuing Telemetry Transport) is a lightweight, publish-subscribe messaging protocol ideal for:

- **IoT devices** - Low bandwidth, minimal battery usage
- **Real-time messaging** - Instant message delivery between clients
- **Remote monitoring** - Send/receive data from distributed devices
- **Home automation** - Connect smart devices seamlessly

This plugin provides a complete MQTT client implementation for Capacitor apps, supporting both Android and iOS.

<br>

This plugin is compatible with Capacitor 7 and above.

Use v6 for Capacitor 6 and below.

**PR's are greatly appreciated.**

## Features

- Connect to MQTT brokers via TCP
- Subscribe to topics with QoS support
- Publish messages with QoS and retained flag options
- Listen for incoming messages
- Automatic reconnection support
- Connection loss detection
- Clean session management
- Keep-alive interval configuration

## Installation

```bash
npm install @capgo/capacitor-mqtt
npx cap sync
```

## Usage

### Connect to MQTT Broker

```typescript
import { MqttBridge } from '@capgo/capacitor-mqtt';

const connectionOptions = {
  serverURI: 'tcp://broker.hivemq.com',
  port: 1883,
  clientId: 'my-client-id',
  username: '',
  password: '',
  setCleanSession: true,
  connectionTimeout: 30,
  keepAliveInterval: 60,
  setAutomaticReconnect: true,
};

await MqttBridge.connect(connectionOptions);
```

### Subscribe to Topic

```typescript
const result = await MqttBridge.subscribe({
  topic: 'my/topic',
  qos: 0,
});
```

### Publish Message

```typescript
const result = await MqttBridge.publish({
  topic: 'my/topic',
  payload: 'Hello World',
  qos: 0,
  retained: false,
});
```

### Listen for Messages

```typescript
import { MqttBridge } from '@capgo/capacitor-mqtt';

MqttBridge.addListener('onMessageArrived', (result) => {
  console.log('Topic:', result.topic);
  console.log('Message:', result.message);
});
```

### Disconnect

```typescript
await MqttBridge.disconnect();
```

## API

<docgen-index>
</docgen-index>

<docgen-api>
</docgen-api>

## License

MPL-2.0
