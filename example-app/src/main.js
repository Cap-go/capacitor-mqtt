import './style.css';
import { MqttBridge } from '@capgo/capacitor-mqtt';

const output = document.getElementById('plugin-output');
const statusBadge = document.getElementById('status-badge');
const connectButton = document.getElementById('connect-button');
const subscribeButton = document.getElementById('subscribe-button');
const publishButton = document.getElementById('publish-button');
const disconnectButton = document.getElementById('disconnect-button');
const serverUriInput = document.getElementById('server-uri');
const serverPortInput = document.getElementById('server-port');
const clientIdInput = document.getElementById('client-id');
const topicInput = document.getElementById('topic');
const payloadInput = document.getElementById('payload');

const eventLog = [];

const setOutput = (value) => {
  if (typeof value === 'string') {
    output.textContent = value;
    return;
  }
  output.textContent = JSON.stringify(value, null, 2);
};

const renderLog = () => {
  output.textContent = eventLog.join('\n\n');
};

const logEvent = (label, payload) => {
  const entry = `[${new Date().toLocaleTimeString()}] ${label}\n${
    typeof payload === 'string' ? payload : JSON.stringify(payload, null, 2)
  }`;
  eventLog.unshift(entry);
  eventLog.splice(12);
  renderLog();
};

const setStatus = (value) => {
  statusBadge.textContent = value;
  statusBadge.dataset.enabled = String(value === 'Connected');
};

const getConnectionOptions = () => ({
  serverURI: `tcp://${serverUriInput.value.trim()}`,
  port: Number(serverPortInput.value || 1883),
  clientId: clientIdInput.value.trim() || `capgo-mqtt-${Date.now()}`,
  username: '',
  password: '',
  setCleanSession: true,
  connectionTimeout: 30,
  keepAliveInterval: 60,
  setAutomaticReconnect: true,
});

const getTopic = () => topicInput.value.trim() || 'capgo/example';

connectButton.addEventListener('click', async () => {
  try {
    const result = await MqttBridge.connect(getConnectionOptions());
    setStatus('Connected');
    logEvent('connect()', result ?? { ok: true });
  } catch (error) {
    setStatus('Error');
    logEvent('connect() error', error?.message ?? error);
  }
});

subscribeButton.addEventListener('click', async () => {
  try {
    const result = await MqttBridge.subscribe({
      topic: getTopic(),
      qos: 0,
    });
    logEvent('subscribe()', result);
  } catch (error) {
    logEvent('subscribe() error', error?.message ?? error);
  }
});

publishButton.addEventListener('click', async () => {
  try {
    const result = await MqttBridge.publish({
      topic: getTopic(),
      payload: payloadInput.value,
      qos: 0,
      retained: false,
    });
    logEvent('publish()', result);
  } catch (error) {
    logEvent('publish() error', error?.message ?? error);
  }
});

disconnectButton.addEventListener('click', async () => {
  try {
    const result = await MqttBridge.disconnect();
    setStatus('Disconnected');
    logEvent('disconnect()', result ?? { ok: true });
  } catch (error) {
    logEvent('disconnect() error', error?.message ?? error);
  }
});

MqttBridge.addListener('onConnectComplete', (result) => {
  setStatus('Connected');
  logEvent('onConnectComplete', result);
}).catch((error) => {
  logEvent('listener error', error?.message ?? error);
});

MqttBridge.addListener('onConnectionLost', (result) => {
  setStatus('Disconnected');
  logEvent('onConnectionLost', result);
}).catch((error) => {
  logEvent('listener error', error?.message ?? error);
});

MqttBridge.addListener('onMessageArrived', (result) => {
  logEvent('onMessageArrived', result);
}).catch((error) => {
  logEvent('listener error', error?.message ?? error);
});

setOutput('Use a native shell to validate broker connectivity. The web implementation may throw for native-only methods.');
