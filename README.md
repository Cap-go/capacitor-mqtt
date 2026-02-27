# @capgo/capacitor-mqtt

<a href="https://capgo.app/"><img src='https://raw.githubusercontent.com/Cap-go/capgo/main/assets/capgo_banner.png' alt='Capgo - Instant updates for capacitor'/></a>

Capacitor plugin for MQTT connectivity on Android and iOS.

## Features

- Connect to MQTT brokers via TCP
- Subscribe to topics
- Publish messages
- Listen for incoming messages
- Automatic reconnection support
- Connection loss detection

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
