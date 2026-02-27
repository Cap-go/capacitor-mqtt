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

* [`connect(...)`](#connect)
* [`disconnect()`](#disconnect)
* [`subscribe(...)`](#subscribe)
* [`publish(...)`](#publish)
* [`addListener('onConnectionLost', ...)`](#addlisteneronconnectionlost-)
* [`addListener('onConnectComplete', ...)`](#addlisteneronconnectcomplete-)
* [`addListener('onMessageArrived', ...)`](#addlisteneronmessagearrived-)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### connect(...)

```typescript
connect(options: { serverURI: string; port: number; clientId: string; username: string; password: string; setCleanSession: boolean; connectionTimeout: number; keepAliveInterval: number; setAutomaticReconnect: boolean; setLastWill?: { willTopic: string; willPayload: string; willQoS: number; setRetained: boolean; }; }) => Promise<any>
```

| Param         | Type                                                                                                                                                                                                                                                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ serverURI: string; port: number; clientId: string; username: string; password: string; setCleanSession: boolean; connectionTimeout: number; keepAliveInterval: number; setAutomaticReconnect: boolean; setLastWill?: { willTopic: string; willPayload: string; willQoS: number; setRetained: boolean; }; }</code> |

**Returns:** <code>Promise&lt;any&gt;</code>

--------------------


### disconnect()

```typescript
disconnect() => Promise<any>
```

**Returns:** <code>Promise&lt;any&gt;</code>

--------------------


### subscribe(...)

```typescript
subscribe(options: { topic: string; qos: number; }) => Promise<{ topic: string; qos: number; }>
```

| Param         | Type                                         |
| ------------- | -------------------------------------------- |
| **`options`** | <code>{ topic: string; qos: number; }</code> |

**Returns:** <code>Promise&lt;{ topic: string; qos: number; }&gt;</code>

--------------------


### publish(...)

```typescript
publish(options: { topic: string; payload: string; qos: number; retained: boolean; }) => Promise<{ topic: string; payload: string; qos: number; retained: boolean; messageId: any; }>
```

| Param         | Type                                                                             |
| ------------- | -------------------------------------------------------------------------------- |
| **`options`** | <code>{ topic: string; payload: string; qos: number; retained: boolean; }</code> |

**Returns:** <code>Promise&lt;{ topic: string; payload: string; qos: number; retained: boolean; messageId: any; }&gt;</code>

--------------------


### addListener('onConnectionLost', ...)

```typescript
addListener(eventName: 'onConnectionLost', listener: onConnectionLostListener) => Promise<PluginListenerHandle>
```

| Param           | Type                                                                          |
| --------------- | ----------------------------------------------------------------------------- |
| **`eventName`** | <code>'onConnectionLost'</code>                                               |
| **`listener`**  | <code><a href="#onconnectionlostlistener">onConnectionLostListener</a></code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('onConnectComplete', ...)

```typescript
addListener(eventName: 'onConnectComplete', listener: onConnectCompleteListener) => Promise<PluginListenerHandle>
```

| Param           | Type                                                                            |
| --------------- | ------------------------------------------------------------------------------- |
| **`eventName`** | <code>'onConnectComplete'</code>                                                |
| **`listener`**  | <code><a href="#onconnectcompletelistener">onConnectCompleteListener</a></code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('onMessageArrived', ...)

```typescript
addListener(eventName: 'onMessageArrived', listener: onMessageArrivedListener) => Promise<PluginListenerHandle>
```

| Param           | Type                                                                          |
| --------------- | ----------------------------------------------------------------------------- |
| **`eventName`** | <code>'onMessageArrived'</code>                                               |
| **`listener`**  | <code><a href="#onmessagearrivedlistener">onMessageArrivedListener</a></code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### Interfaces


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


### Type Aliases


#### onConnectionLostListener

<code>(x: { connectionStatus: string; reasonCode: number; message: string; }): void</code>


#### onConnectCompleteListener

<code>(x: { reconnected: boolean; serverURI: string; }): void</code>


#### onMessageArrivedListener

<code>(x: { topic: string; message: string; }): void</code>

</docgen-api>

## License

MPL-2.0
