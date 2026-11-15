import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { test } from 'node:test';

const html = readFileSync(new URL('../../assets/call/lesson_call_stage.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const mediaContract = readFileSync(new URL('../../assets/call/lesson-media-command.js', import.meta.url), 'utf8');
const flush = async () => { for (let i = 0; i < 10; i++) await Promise.resolve(); };

test('native call address preserves the provider domain and refuses foreign or incomplete breakout addresses', () => {
  const c = stage().context;
  const pass = { room: 'provider', roomJid: 'provider@breakout.meet.jitsi', mainRoom: 'lesson', xmppDomain: 'meet.jitsi' };
  assert.deepEqual(JSON.parse(JSON.stringify(c.callAddress(pass))), { room: 'provider', mainRoom: 'lesson', customDomain: 'breakout.meet.jitsi' });
  assert.deepEqual(JSON.parse(JSON.stringify(c.callAddress({ room: 'lesson', xmppDomain: 'meet.jitsi' }))), { room: 'lesson', mainRoom: 'lesson' });
  for (const invalid of [{ roomJid: 'provider@evil.test' }, { roomJid: 'other@breakout.meet.jitsi' },
    { mainRoom: 'provider' }, { mainRoom: '*' }, { mainRoom: undefined }, { roomJid: undefined }]) {
    assert.equal(c.callAddress({ ...pass, ...invalid }), null);
  }
  assert.notEqual(c.callAddressKey(pass), c.callAddressKey({ room: pass.room }));
});

test('native bootstrap receives no media, cancels late leave, and has a finite deadline', async () => {
  const f = stage(), c = f.context, handlers = new Map(), calls = [];
  let resolveLeave;
  const main = { on: (event, fn) => handlers.set(event, fn), off: event => handlers.delete(event),
    setReceiverConstraints: value => calls.push(JSON.parse(JSON.stringify(value))),
    join: () => calls.push('join-main'), leave: () => { calls.push('leave-main'); return new Promise(resolve => { resolveLeave = resolve; }); } };
  const cancel = c.bootstrapBreakout({ create: () => main, joinedEvent: 'joined', failedEvent: 'failed', current: () => true,
    ready: () => calls.push('target'), failed: () => calls.push('failed') });
  assert.deepEqual(calls, [{ lastN: 0, defaultConstraints: { maxHeight: 0 } }, 'join-main']);
  handlers.get('joined')(); cancel(); resolveLeave(); await flush();
  assert.equal(calls.includes('target'), false);
  c.bootstrapBreakout({ create: () => main, joinedEvent: 'joined', failedEvent: 'failed', current: () => true,
    ready: () => calls.push('target'), failed: () => calls.push('failed') });
  await f.advance(10001);
  assert.equal(calls.filter(value => value === 'failed').length, 1);
  assert.equal(calls.includes('target'), false);
});

function jitsi(c) {
  const connections = [], conferences = [], calls = [];
  const conferenceEvents = Object.fromEntries(['TRACK_ADDED', 'TRACK_REMOVED', 'TRACK_MUTE_CHANGED', 'USER_JOINED', 'USER_LEFT',
    'DISPLAY_NAME_CHANGED', 'CONFERENCE_JOINED', 'CONFERENCE_FAILED'].map(key => [key, key]));
  class Connection {
    constructor(_app, token, options) { this.token = token; this.options = options; this.handlers = new Map(); connections.push(this); }
    addEventListener(event, fn) { this.handlers.set(event, fn); }
    connect() { this.handlers.get('established')(); }
    disconnect() { calls.push(['disconnect']); }
    initJitsiConference(name, options) {
      const handlers = new Map(), conn = this;
      const conf = { name, options, handlers, setDisplayName() {}, addCommandListener() {},
        myUserId: () => 'self-endpoint', getParticipantById: () => null,
        on: (event, fn) => handlers.set(event, fn), off: event => handlers.delete(event),
        setReceiverConstraints: value => calls.push(['receive', name, JSON.parse(JSON.stringify(value))]),
        addTrack: value => { calls.push(['publish', name, value.source]); return Promise.resolve(); },
        join() { assert.ok(!options.customDomain || conn.wasInMain); calls.push(['join', name]); },
        leave() { conn.wasInMain = true; calls.push(['leave', name]); return Promise.resolve(); } };
      conferences.push(conf); return conf;
    }
  }
  c.window.JitsiMeetJS = { init() {}, JitsiConnection: Connection, events: {
    connection: { CONNECTION_FAILED: 'failed', CONNECTION_ESTABLISHED: 'established' }, conference: conferenceEvents } };
  c.render = () => {};
  return { connections, conferences, calls };
}

const mainPass = { displayName: 'Pupil', domain: 'meet.example.test', xmppDomain: 'meet.jitsi',
  jwt: 'synthetic-main-scoped-token', room: 'lesson' };
const breakoutPass = { ...mainPass, room: 'provider', roomJid: 'provider@breakout.meet.jitsi', mainRoom: 'lesson' };

test('actual native start joins and leaves main before the confirmed breakout on the same authenticated connection', async () => {
  const f = stage(), c = f.context, { connections, conferences, calls } = jitsi(c);
  c.start(breakoutPass);
  assert.equal(conferences.length, 1);
  assert.equal(conferences[0].name, 'lesson');
  assert.equal(f.events.some(e => ['endpoint', 'joined'].includes(e[1].kind)), false);
  conferences[0].handlers.get('CONFERENCE_JOINED')(); await flush();
  assert.equal(connections.length, 1);
  assert.equal(connections[0].options.serviceUrl, 'wss://meet.example.test/xmpp-websocket?room=lesson');
  assert.equal(conferences.length, 2);
  assert.equal(conferences[1].name, 'provider');
  assert.equal(conferences[1].options.customDomain, 'breakout.meet.jitsi');
  for (const conference of conferences) {
    const quality = JSON.parse(JSON.stringify(conference.options.videoQuality));
    assert.deepEqual(quality.codecPreferenceOrder, ['VP8', 'VP9', 'H264', 'AV1']);
    assert.deepEqual(quality.mobileCodecPreferenceOrder, quality.codecPreferenceOrder);
    assert.equal(quality.screenshareCodec, 'VP8');
    assert.equal(quality.mobileScreenshareCodec, 'VP8');
  }
  assert.deepEqual(calls.filter(value => ['join', 'leave'].includes(value[0])), [['join', 'lesson'], ['leave', 'lesson'], ['join', 'provider']]);
});

test('native room changes wait for the pending exit and discard superseded renew and hold continuations', async () => {
  const f = stage(), c = f.context, calls = [];
  let release;
  c.room = { leave: () => new Promise(resolve => { release = resolve; }) };
  c.connection = { disconnect: () => calls.push('disconnect') };
  c.join = pass => calls.push(pass.room);
  const hold = c.holdRoom();
  const staleRenew = c.acceptPass(mainPass);
  const newRoom = c.switchRoom(breakoutPass);
  await flush();
  assert.deepEqual(calls, []);
  release();
  await Promise.all([hold, staleRenew, newRoom]);
  assert.deepEqual(calls, ['disconnect', 'provider']);
  assert.equal(f.events.some(([, event]) => event.kind === 'holding'), false);

  c.room = { leave: () => new Promise(resolve => { release = resolve; }) };
  const lateRenew = c.acceptPass(breakoutPass);
  const newHold = c.holdRoom();
  release();
  await Promise.all([lateRenew, newHold]);
  assert.deepEqual(calls, ['disconnect', 'provider']);
  assert.equal(f.events.filter(([, event]) => event.kind === 'holding').length, 1);
});

test('native room exit times out a hung leave and disconnects the retired connection only once', async () => {
  const f = stage(), c = f.context, calls = [];
  let release;
  c.room = { leave: () => new Promise(resolve => { release = resolve; }) };
  c.connection = { disconnect: () => calls.push('disconnect') };
  c.join = pass => calls.push(pass.room);
  const changing = c.switchRoom(breakoutPass);
  await f.advance(9999);
  assert.deepEqual(calls, []);
  await f.advance(1);
  await changing;
  release();
  await flush();
  assert.deepEqual(calls, ['disconnect', 'provider']);
});

test('native learner republishes the same camera and microphone after room entry, renewal and return', async () => {
  const f = stage(), c = f.context, { conferences, calls } = jitsi(c);
  const camera = track('camera', true), mic = track('mic', true);
  c.join(mainPass);
  conferences[0].handlers.get('CONFERENCE_JOINED')();
  c.storeLocalTrack('video', camera);
  c.storeLocalTrack('audio', mic);
  c.wishMuted = { video: false, audio: false };

  for (const [pass, renew] of [[breakoutPass, false], [breakoutPass, true], [mainPass, false]]) {
    const index = conferences.length;
    const hold = c.holdRoom(!renew);
    await (renew ? c.acceptPass(pass) : c.switchRoom(pass));
    await hold;
    if (pass.mainRoom) {
      conferences[index].handlers.get('CONFERENCE_JOINED')();
      await flush();
    }
    conferences.at(-1).handlers.get('CONFERENCE_JOINED')();
    await flush();
  }
  assert.equal(c.localVideo, camera);
  assert.equal(c.localAudio, mic);
  assert.deepEqual(calls.filter(value => value[0] === 'publish'), [
    ['publish', 'provider', 'camera'], ['publish', 'provider', 'mic'],
    ['publish', 'provider', 'camera'], ['publish', 'provider', 'mic'],
    ['publish', 'lesson', 'camera'], ['publish', 'lesson', 'mic'],
  ]);
  assert.equal(f.events.filter(([, event]) => event.kind === 'camera-on').length, 3);
  assert.equal(f.events.filter(([, event]) => event.kind === 'mic-on').length, 3);
});

test('native participant identity retains an equal-name peer and detaches audio on track removal and departure', async () => {
  const f = stage(), c = f.context, { conferences } = jitsi(c), audioNodes = [];
  c.document.body = {
    appendChild(node) { node.parentNode = this; audioNodes.push(node); },
    removeChild(node) { audioNodes.splice(audioNodes.indexOf(node), 1); node.parentNode = null; },
  };
  c.document.createElement = () => ({ setAttribute() {}, play: () => Promise.resolve() });
  c.join(mainPass);
  const handlers = conferences[0].handlers;
  handlers.get('CONFERENCE_JOINED')();
  const peer = 'peer-endpoint';
  handlers.get('USER_JOINED')(peer, { getDisplayName: () => mainPass.displayName });
  assert.deepEqual(Array.from(c.orderedPeople(), person => person.id), ['local', peer]);

  const makeAudio = source => Object.assign(track(source), { getType: () => 'audio', getParticipantId: () => peer });
  const first = makeAudio('first'), replacement = makeAudio('replacement');
  handlers.get('TRACK_ADDED')(first);
  handlers.get('TRACK_ADDED')(first);
  await flush();
  assert.equal(audioNodes.length, 1);
  handlers.get('TRACK_ADDED')(replacement);
  handlers.get('TRACK_REMOVED')(first);
  await flush();
  assert.equal(first.detaches, 1);
  assert.equal(audioNodes.length, 1);
  assert.equal(audioNodes[0].srcObject, replacement.stream);
  assert.equal(c.people[peer].audioMuted, false);

  let finishAttach;
  const delayed = makeAudio('late');
  delayed.attach = node => new Promise(resolve => { finishAttach = () => { node.srcObject = delayed.stream; resolve(); }; });
  handlers.get('TRACK_ADDED')(delayed);
  const delayedNode = audioNodes.at(-1);
  handlers.get('USER_LEFT')(peer);
  finishAttach();
  await flush();
  assert.equal(audioNodes.length, 0);
  assert.equal(replacement.detaches, 1);
  assert.equal(delayedNode.srcObject, null);
  assert.equal(c.remoteAudios.size, 0);
});
function stage() {
  let now = 100000, next = 0;
  const timers = new Map(), events = [];
  const setTimeout = (fn, ms = 0) => { timers.set(++next, { at: now + ms, fn }); return next; };
  const clearTimeout = id => timers.delete(id);
  const context = vm.createContext({ Promise, TextEncoder, console,
    Date: class extends Date { static now() { return now; } }, setTimeout, clearTimeout,
    document: { hidden: false, getElementById: () => null },
    window: { setTimeout, clearTimeout, flutter_inappwebview: { callHandler: (...args) => events.push(args) } },
  });
  vm.runInContext(mediaContract, context);
  vm.runInContext(script, context);
  return { context, events, timers, async advance(ms) {
    const until = now + ms;
    for (;;) {
      const ready = [...timers].filter(([, value]) => value.at <= until).sort((a, b) => a[1].at - b[1].at)[0];
      if (!ready) break;
      timers.delete(ready[0]); now = ready[1].at; ready[1].fn(); await flush();
    }
    now = until; await flush();
  } };
}
function video(height = 160) {
  return { isConnected: true, srcObject: null, currentTime: 0, frames: 0,
    getBoundingClientRect: () => ({ width: 240, height }),
    getVideoPlaybackQuality() { return { totalVideoFrames: this.frames }; },
    play: () => Promise.resolve(),
  };
}
function track(source, local = false) {
  return { source, stream: { source }, containers: [], attaches: 0, detaches: 0,
    getSourceName: () => source, isLocal: () => local, isMuted: () => false,
    attach(element) { this.attaches++; this.containers.push(element); element.srcObject = this.stream; return Promise.resolve(); },
    detach(element) {
      this.detaches++;
      const targets = element ? [element] : [...this.containers];
      for (const target of targets) target.srcObject = null;
      this.containers = this.containers.filter(item => !targets.includes(item));
    },
  };
}

test('actual native board binding owns each connected element once and ignores stale endpoint cleanup', async () => {
  const f = stage(), c = f.context, element = video(), a = track('a-v0'), b = track('b-v0');
  c.people = { a: { camera: a }, b: { camera: b } };
  c.bindBoardVideo('a', element); c.bindBoardVideo('a', element);
  assert.equal(a.attaches, 1);
  c.bindBoardVideo('b', element);
  await flush();
  assert.equal(a.containers.length, 0);
  assert.equal(element.srcObject, b.stream);
  c.bindBoardVideo('a', null, element);
  a.detach();
  assert.equal(element.srcObject, b.stream);
  assert.equal(b.containers.length, 1);
  c.bindBoardVideo('b', null, element);
  assert.equal(element.srcObject, null);
  assert.equal(c.boardVideoBindings.size, 0);
  c.clearVideoBindings();
  assert.equal(f.timers.size, 0);
});

test('actual native mute listener retains an initially muted camera and supplies it after unmute and remount', async () => {
  const f = stage(), c = f.context, camera = track('child-v0'), first = video(), second = video();
  let muted = true;
  Object.assign(camera, { getParticipantId: () => 'child', getType: () => 'video', getVideoType: () => 'camera', isMuted: () => muted });
  const handlers = new Map(), snapshots = [];
  c.room = { on: (event, handler) => handlers.set(event, handler) };
  c.meet = { events: { conference: { TRACK_MUTE_CHANGED: 'mute' } } };
  c.thisAttempt = c.attempt;
  c.boardInstalled = true;
  c.window.LarnesBoard = { setParticipantMedia: value => snapshots.push(value) };
  // The DOM/render boundary is synthetic; registration, camera bookkeeping and SDK bridge are real HTML functions.
  c.render = () => c.syncBoardPeople();
  const registration = script.slice(script.indexOf('          room.on(meet.events.conference.TRACK_MUTE_CHANGED,'), script.indexOf('          room.on(meet.events.conference.USER_JOINED,'));
  vm.runInContext(registration, c);
  c.rememberVideo(camera);
  assert.equal(c.people.child.camera, camera);
  assert.equal(snapshots.at(-1).endpoints[0].videoMuted, true);
  muted = false; handlers.get('mute')(camera);
  assert.equal(snapshots.at(-1).endpoints[0].videoMuted, false);
  c.bindBoardVideo('child', first);
  assert.equal(first.srcObject, camera.stream);
  muted = true; handlers.get('mute')(camera);
  c.bindBoardVideo('child', null, first);
  assert.equal(first.srcObject, null);
  assert.equal(c.people.child.camera, camera);
  muted = false; handlers.get('mute')(camera);
  c.bindBoardVideo('child', second);
  assert.equal(second.srcObject, camera.stream);
  assert.equal(camera.attaches, 2);
  c.clearVideoBindings();
  await f.advance(0);
  assert.equal(f.timers.size, 0);
});

test('releasing one of two views preserves the other and a late attach failure cannot affect a new owner', async () => {
  const f = stage(), c = f.context, a = track('a-v0'), b = track('b-v0'), first = video(), second = video();
  let fail;
  a.attach = function (element) { this.attaches++; this.containers.push(element); element.srcObject = this.stream; return new Promise((_, reject) => { fail = reject; }); };
  c.bindVideoTrack(a, first); c.bindVideoTrack(a, second);
  c.unbindVideoTrack(first, a);
  assert.equal(second.srcObject, a.stream);
  c.bindVideoTrack(b, first);
  fail(new Error('old autoplay rejection')); await flush();
  assert.equal(first.srcObject, b.stream);
  assert.equal(c.boardVideoBindings.get(first).failed, false);
  c.clearVideoBindings();
});

test('first-frame recovery reattaches only a stalled remote view, is bounded, and resets after real progress', async () => {
  const f = stage(), c = f.context, a = track('a-v0'), element = video();
  c.bindVideoTrack(a, element); await flush();
  await f.advance(35000);
  assert.equal(a.attaches, 3); // initial + two soft recoveries; no conference join.
  await f.advance(40000);
  assert.equal(a.attaches, 3);
  element.frames = 1; element.currentTime = 1;
  await f.advance(2000);
  await f.advance(14000);
  assert.equal(a.attaches, 4);
  c.clearVideoBindings();
});

test('hidden and local views do not trigger frame recovery, disconnected views are released', async () => {
  const f = stage(), c = f.context, local = track('own-v0', true), remote = track('other-v0'), own = video(), other = video();
  c.bindVideoTrack(local, own); c.bindVideoTrack(remote, other);
  c.document.hidden = true;
  await f.advance(40000);
  assert.equal(local.attaches, 1); assert.equal(remote.attaches, 1);
  other.isConnected = false;
  await f.advance(2000);
  assert.equal(remote.containers.length, 0);
  c.document.hidden = false;
  await f.advance(30000);
  assert.equal(local.attaches, 1);
  c.clearVideoBindings();
});

test('receiver quality uses source names and the largest visible view, excluding local and hidden video', async () => {
  const f = stage(), c = f.context, a = track('a-v0'), b = track('b-v0'), own = track('own-v0', true);
  const updates = [];
  c.room = { setReceiverConstraints: settings => updates.push(settings) }; c.callJoined = true;
  c.people = { a: { camera: a }, b: { camera: b }, local: { local: true, camera: own } };
  c.bindVideoTrack(a, video(120)); c.bindVideoTrack(a, video(700)); c.bindVideoTrack(b, video(300)); c.bindVideoTrack(own, video(900));
  await f.advance(0);
  const settings = updates.at(-1);
  assert.equal(settings.constraints['a-v0'].maxHeight, 720);
  assert.equal(settings.constraints['b-v0'].maxHeight, 360);
  assert.equal(settings.constraints['own-v0'], undefined);
  assert.deepEqual([...settings.selectedSources], ['a-v0']);
  c.applyVideoReceive(); assert.equal(updates.length, 1);
  c.document.hidden = true; c.applyVideoReceive();
  assert.equal(updates.at(-1).constraints['a-v0'].maxHeight, 0);
  c.clearVideoBindings();
});

test('publication retries a rejected addTrack without opening another camera or overlapping requests', async () => {
  const f = stage(), c = f.context, camera = track('camera-v0', true);
  let tries = 0;
  const room = { addTrack: () => ++tries === 1 ? Promise.reject(new Error('temporary signaling failure')) : Promise.resolve() };
  c.room = room;
  const sent = c.publishLocalTrack(camera, room, c.attempt);
  assert.equal(c.publishLocalTrack(camera, room, c.attempt), sent);
  await flush(); await f.advance(300);
  assert.equal(await sent, true); assert.equal(tries, 2); assert.equal(c.publicationTasks.size, 0);
});

test('publication retries are bounded and cancellation fences late success or failures from the old room', async () => {
  const f = stage(), c = f.context, camera = track('camera-v0', true);
  let tries = 0;
  const room = { addTrack: () => { tries++; return Promise.reject(new Error('failed')); } };
  c.room = room;
  const failed = c.publishLocalTrack(camera, room, c.attempt);
  await flush(); await f.advance(1300);
  assert.equal(await failed, false); assert.equal(tries, 3); assert.equal(c.publicationTasks.size, 0);
  let finishOld;
  const oldRoom = { addTrack: () => new Promise(resolve => { finishOld = resolve; }) };
  c.room = oldRoom;
  const old = c.publishLocalTrack(camera, oldRoom, c.attempt);
  c.attempt++; c.clearPublicationTasks();
  assert.equal(await old, false);
  c.room = { addTrack: () => Promise.resolve() };
  assert.equal(await c.publishLocalTrack(camera, c.room, c.attempt), true);
  finishOld(); await flush();
  assert.equal(c.publicationTasks.size, 0); assert.equal(f.timers.size, 0);
});

test('a hung publication times out without starting parallel addTrack attempts', async () => {
  const f = stage(), c = f.context;
  let tries = 0;
  c.room = { addTrack: () => { tries++; return new Promise(() => {}); } };
  const sent = c.publishLocalTrack(track('own-v0', true), c.room, c.attempt);
  await f.advance(6000);
  assert.equal(await sent, false); assert.equal(tries, 1); assert.equal(c.publicationTasks.size, 0);
});

test('observer endpoints stay hidden and can control only targeted media under a fresh roster lease', async () => {
  const f = stage(), c = f.context;
  vm.runInContext(`setTeachers(['teacher'], 'teacher', ['teacher','observer'], ['observer']);
    people = { local: {id:'local',local:true,name:'Child'}, child:{id:'child',name:'Child'},
      observer:{id:'observer',name:'Teacher observer'}, teacher:{id:'teacher',name:'Teacher'} };
    localEndpoint='child';`, c);
  assert.deepEqual([...c.orderedPeople()].map(p => p.id), ['local', 'teacher']);
  const command = { target: 'child', device: 'video', muted: true, sentAt: 100001 };
  assert.equal(c.decideCommand(command, 'observer'), 'apply');
  assert.equal(c.decideCommand({ ...command, target: 'someone-else' }, 'observer'), 'drop');
  assert.equal(c.decideCommand(command, 'stranger'), 'drop');
  assert.equal(c.knownTeacher('observer'), false);
  assert.deepEqual([...c.teacherIds], ['teacher']);
  await f.advance(5001);
  assert.equal(c.decideCommand(command, 'observer'), 'drop');
  assert.equal(c.decideCommand(command, 'teacher'), 'drop', 'teachers also require a fresh server lease');
  vm.runInContext(`setTeachers(['teacher'], 'teacher', ['teacher','observer'], ['observer'])`, c);
  assert.equal(c.decideCommand(command, 'observer'), 'apply');
  vm.runInContext(`setTeachers(['teacher'],'teacher')`, c);
  assert.equal(c.decideCommand(command, 'observer'), 'drop');
  const hinted = { id: 'stranger', name: 'Role hint only' };
  c.applyCallRole(hinted, { getIdentity: () => ({ user: { id: 'observer:teacher-1' } }) });
  assert.equal(hinted.observer, true);
  assert.equal(c.decideCommand(command, hinted.id), 'drop', 'presentation hints do not grant command authority');
  c.applyCallRole(hinted, { getIdentity: () => ({ user: { id: 'teacher:teacher-1' } }) });
  assert.equal(hinted.observer, false);
});

function correlatedMedia() {
  const f = stage(), c = f.context, sent = [], changes = [];
  let muted = true;
  const camera = { isMuted: () => muted, getType: () => 'video', getTrack: () => ({ readyState: 'live' }),
    mute: async () => { muted = true; changes.push('mute'); }, unmute: async () => { muted = false; changes.push('unmute'); }, dispose() {} };
  c.render = () => {};
  c.room = { sendEndpointMessage: (target, result) => sent.push({ target, result: JSON.parse(JSON.stringify(result)) }),
    addTrack: async () => { changes.push('publish'); }, leave: async () => {}, removeTrack: async () => {} };
  c.callJoined = true; c.localEndpoint = 'child'; c.passHold = { room: 'lesson' };
  c.localVideo = camera;
  c.window.flutter_inappwebview.callHandler = async (name, detail) => {
    if (name === 'lessonMediaPermission') return { ok: true };
    f.events.push([name, detail]);
  };
  vm.runInContext("setTeachers(['teacher'], 'teacher', ['teacher', 'observer'], ['observer'])", c);
  const command = (overrides = {}) => ({ kind: 'larnes-media', version: 2, device: 'video', muted: false,
    commandId: 'command-1', scopeId: 'lesson', room: 'lesson', generation: 'teacher-gen', target: 'child', sentAt: 100001, expiresAt: 110001, ...overrides });
  return { ...f, c, camera, sent, changes, command, get muted() { return muted; }, setMuted: value => { muted = value; } };
}

test('native v2 reports actual published state and repeats the ACK without repeating device work', async () => {
  const f = correlatedMedia(), command = f.command();
  f.c.onEndpointMessage('observer', command); await flush(); await flush();
  assert.deepEqual(f.sent.map(item => item.result.status), ['pending', 'applied']);
  assert.deepEqual(f.changes, ['unmute', 'publish']);
  assert.equal(f.muted, false);
  assert.equal(f.sent[1].target, 'observer');
  assert.equal(f.sent[1].result.commandId, command.commandId);
  assert.equal(f.sent[1].result.generation, command.generation);
  f.c.onEndpointMessage('observer', command); await flush();
  assert.deepEqual(f.sent.map(item => item.result.status), ['pending', 'applied', 'applied']);
  assert.deepEqual(f.changes, ['unmute', 'publish']);
  f.c.clearTeacherMedia();
  assert.equal(f.timers.size, 0);
});

test('native v2 permits the SDK to reacquire a normally muted camera and requires the new live track', async () => {
  const f = correlatedMedia();
  let ended = true;
  f.camera.getTrack = () => ({ readyState: ended ? 'ended' : 'live' });
  const unmute = f.camera.unmute;
  f.camera.unmute = async () => { await unmute(); ended = false; };
  f.c.onEndpointMessage('teacher', f.command()); await flush(); await flush();
  assert.equal(f.sent.at(-1).result.status, 'applied');
  assert.equal(ended, false);
  f.setMuted(true); ended = true; f.camera.unmute = unmute;
  f.c.onEndpointMessage('teacher', f.command({ commandId: 'failed-recapture', sentAt: 100002 })); await flush(); await flush();
  assert.equal(f.sent.at(-1).result.status, 'rejected');
  assert.equal(f.sent.at(-1).result.reason, 'missing');
  f.c.clearTeacherMedia();
});

test('native hardware loss releases 100 captures and permits retry without retaining old stop listeners', async () => {
  const f = correlatedMedia(), c = f.c;
  c.localVideo = null; c.deviceAllowed.video = true;
  c.window.JitsiMeetJS = { events: { track: { LOCAL_TRACK_STOPPED: 'track.stopped' } }, createLocalTracks: async () => {
    let muted = false, ended = false;
    const listeners = new Set();
    return [{ getType: () => 'video', getTrack: () => ({ readyState: ended ? 'ended' : 'live' }), isMuted: () => muted,
      mute: async () => { muted = true; ended = true; }, unmute: async () => { muted = false; ended = false; },
      addEventListener: (_name, callback) => listeners.add(callback), removeEventListener: (_name, callback) => listeners.delete(callback),
      dispose: () => { for (const callback of listeners) callback(); }, listeners,
      stop: () => { ended = true; for (const callback of listeners) callback(); } }];
  } };
  for (let cycle = 0; cycle < 100; cycle++) {
    c.askDevice('video', false); await flush(); await flush();
    const capture = c.localVideo;
    assert.ok(capture); assert.equal(c.videoMuted, false);
    const oldStop = [...capture.listeners][0];
    capture.stop();
    assert.equal(c.videoMuted, true); assert.equal(c.localVideo, null);
    assert.equal(c.localDeviceListeners.size, 0); assert.equal(capture.listeners.size, 0);
    assert.equal(c.publishedLocalTracks.size, 0); assert.equal(c.publicationTasks.size, 0);
    const messages = f.events.length; oldStop();
    assert.equal(f.events.length, messages);
  }
  c.askDevice('video', false); await flush(); await flush();
  const capture = c.localVideo;
  c.askDevice('video', true); await flush();
  for (const callback of capture.listeners) callback();
  assert.equal(c.localVideo, capture, 'deliberate mute retains the reusable SDK track');
  c.askDevice('video', false); await flush();
  assert.equal(capture.getTrack().readyState, 'live');
  c.leaving = true; c.localVideo = null; c.releaseTrack(capture);
  assert.equal(c.localDeviceListeners.size, 0);
  c.clearTeacherMedia(); c.clearPublicationTasks();
});

test('native v2 never acknowledges a capture that ends while its publication is pending', async () => {
  for (const absent of [false, true]) {
    const f = correlatedMedia(), c = f.c;
    let finish, live = true, released = 0;
    c.localVideo = null;
    f.setMuted(false);
    f.camera.getTrack = () => live ? { readyState: 'live' } : absent ? null : { readyState: 'ended' };
    f.camera.dispose = () => { released++; };
    c.window.JitsiMeetJS = { createLocalTracks: async () => [f.camera] };
    c.room.addTrack = () => new Promise(resolve => { finish = resolve; });
    c.onEndpointMessage('teacher', f.command()); await flush();
    assert.equal(f.sent.at(-1).result.status, 'pending');
    live = false; finish(); await flush(); await flush();
    assert.equal(f.sent.at(-1).result.status, 'rejected'); assert.equal(f.sent.at(-1).result.reason, 'missing');
    assert.equal(c.localVideo, null); assert.equal(released, 1); assert.equal(c.publishedLocalTracks.size, 0);
    c.clearTeacherMedia(); c.clearPublicationTasks();
  }
});

test('native v2 refuses bad scope, room, authority and malformed packets instead of running legacy actions', async () => {
  const f = correlatedMedia();
  for (const overrides of [{ scopeId: 'other' }, { room: 'other' }, { target: 'other' }, { version: 3 },
    { version: undefined }, { commandId: '' }, { expiresAt: 111001 }, { expiresAt: 99999 }]) {
    f.c.onEndpointMessage('teacher', f.command(overrides));
  }
  f.c.onEndpointMessage('stranger', f.command());
  await f.advance(5001);
  f.c.onEndpointMessage('teacher', f.command());
  assert.deepEqual(f.sent, []); assert.deepEqual(f.changes, []);
  assert.equal(f.events.some(([, value]) => value.kind === 'teacher-media'), false);
});

test('native v2 reports Android denial and failed publication without a false applied ACK', async () => {
  const denied = correlatedMedia();
  denied.c.window.flutter_inappwebview.callHandler = async () => ({ ok: false, reason: 'denied' });
  denied.c.onEndpointMessage('teacher', denied.command()); await flush();
  assert.equal(denied.sent.at(-1).result.reason, 'denied');
  assert.deepEqual(denied.changes, []);
  const browserDenied = correlatedMedia();
  browserDenied.c.localVideo = null;
  browserDenied.c.window.JitsiMeetJS = { createLocalTracks: async () => { throw Object.assign(new Error('denied'), { name: 'NotAllowedError' }); } };
  browserDenied.c.onEndpointMessage('teacher', browserDenied.command()); await flush();
  assert.equal(browserDenied.sent.at(-1).result.status, 'rejected');
  assert.equal(browserDenied.sent.at(-1).result.reason, 'denied');
  assert.deepEqual(browserDenied.changes, []);
  const unavailable = correlatedMedia();
  unavailable.c.room.addTrack = () => new Promise(() => {});
  unavailable.c.onEndpointMessage('teacher', unavailable.command()); await flush();
  await unavailable.advance(6001);
  assert.equal(unavailable.sent.at(-1).result.status, 'rejected');
  assert.equal(unavailable.sent.at(-1).result.reason, 'unpublished');
  assert.equal(unavailable.muted, true);
  assert.equal(unavailable.timers.size, 0);
});

test('native publication bookkeeping releases 100 replaced tracks and rejects camera enable while sharing', async () => {
  const f = correlatedMedia();
  for (let cycle = 0; cycle < 100; cycle++) {
    const camera = { ...f.camera };
    assert.equal(await f.c.publishLocalTrack(camera, f.c.room, f.c.attempt), true);
    assert.equal(f.c.publishedLocalTracks.size, 1);
    f.c.releaseTrack(camera);
    assert.equal(f.c.publishedLocalTracks.size, 0);
    assert.equal(f.c.publicationTasks.size, 0);
    const pending = f.c.publishLocalTrack(camera, f.c.room, f.c.attempt);
    f.c.releaseTrack(camera);
    assert.equal(await pending, false);
    await flush();
    assert.equal(f.c.publishedLocalTracks.size, 0, 'late publication must not revive a disposed track');
    assert.equal(f.c.publicationTasks.size, 0);
  }
  f.changes.length = 0;
  f.c.shareState = 'on';
  f.c.onEndpointMessage('teacher', f.command()); await flush();
  assert.equal(f.sent.at(-1).result.status, 'rejected');
  assert.equal(f.sent.at(-1).result.reason, 'route-locked');
  assert.deepEqual(f.changes, []);
});

test('native v2 fences late permission after replacement, local action, room change and deadline', async () => {
  for (const cancel of ['replacement', 'local', 'room', 'deadline']) {
    const f = correlatedMedia(); let permit;
    f.c.window.flutter_inappwebview.callHandler = (_name, request) => request.muted
      ? Promise.resolve({ ok: true }) : new Promise(resolve => { permit = resolve; });
    f.c.onEndpointMessage('teacher', f.command()); await flush();
    if (cancel === 'replacement') f.c.onEndpointMessage('teacher', f.command({ commandId: 'command-2', sentAt: 100002, expiresAt: 110002, muted: true }));
    if (cancel === 'local') { f.c.window.JitsiMeetJS = {}; f.c.setDevice('video', true); }
    if (cancel === 'room') f.c.leaveConferenceOnly();
    if (cancel === 'deadline') await f.advance(10002);
    await flush(); permit({ ok: true }); await flush();
    assert.equal(f.changes.includes('unmute'), false, cancel);
    assert.equal(f.sent.some(item => item.result.commandId === 'command-1' && item.result.status === 'applied'), false, cancel);
    assert.equal(f.muted, true, cancel);
    f.c.clearTeacherMedia();
  }
});

test('native v2 mutes an unmute promise that finishes after its command deadline', async () => {
  const f = correlatedMedia(); let finishUnmute;
  f.camera.unmute = () => new Promise(resolve => { finishUnmute = () => { f.setMuted(false); resolve(); }; });
  f.c.onEndpointMessage('teacher', f.command()); await flush();
  await f.advance(10002); finishUnmute(); await flush();
  assert.equal(f.muted, true);
  assert.equal(f.sent.at(-1).result.status, 'rejected');
  assert.equal(f.sent.some(item => item.result.status === 'applied'), false);
  assert.equal(f.changes.includes('publish'), false);
});

test('native v2 disposes a capture that resolves after expiry and preserves legacy bridge commands', async () => {
  const f = correlatedMedia(); let finishCapture, disposed = 0;
  f.c.localVideo = null;
  f.camera.dispose = () => { disposed++; };
  f.c.window.JitsiMeetJS = { createLocalTracks: () => new Promise(resolve => { finishCapture = resolve; }) };
  f.c.onEndpointMessage('teacher', f.command()); await flush();
  await f.advance(10002); finishCapture([f.camera]); await flush();
  assert.equal(disposed, 1); assert.equal(f.c.localVideo, null);
  assert.equal(f.changes.includes('publish'), false);
  f.c.setTeachers(['teacher'], 'teacher', ['teacher']);
  f.c.onEndpointMessage('teacher', { kind: 'larnes-media', target: 'child', device: 'audio', muted: true, sentAt: 110003 });
  assert.equal(f.events.at(-1)[1].kind, 'teacher-media');
  assert.equal(f.events.at(-1)[1].detail, 'audio:1');
});

test('native mute ACK prevents an already opening local camera from publishing later', async () => {
  const f = correlatedMedia(); let finishCapture, disposed = 0;
  f.c.localVideo = null; f.c.deviceAllowed.video = true; f.c.wishMuted.video = false;
  f.camera.dispose = () => { disposed++; };
  f.c.window.JitsiMeetJS = { createLocalTracks: () => new Promise(resolve => { finishCapture = resolve; }) };
  f.c.beginCapture('video');
  f.c.onEndpointMessage('teacher', f.command({ muted: true })); await flush();
  assert.equal(f.sent.at(-1).result.status, 'applied');
  f.c.onEndpointMessage('teacher', f.command({ commandId: 'camera-on-again', sentAt: 100002, expiresAt: 110002 })); await flush();
  assert.equal(f.sent.at(-1).result.reason, 'busy');
  finishCapture([f.camera]); await flush();
  assert.equal(disposed, 1); assert.equal(f.c.localVideo, null);
  assert.equal(f.c.opening.video, false);
  assert.equal(f.changes.includes('publish'), false);
});

test('native mute waits until a pending local publication is muted before applied ACK', async () => {
  const f = correlatedMedia(); let finishMute, disposed = 0;
  f.c.localVideo = null; f.c.pending.video = f.camera; f.setMuted(false);
  f.camera.dispose = () => { disposed++; };
  f.camera.mute = () => new Promise(resolve => { finishMute = () => { f.setMuted(true); resolve(); }; });
  f.c.onEndpointMessage('teacher', f.command({ muted: true })); await flush();
  assert.deepEqual(f.sent.map(item => item.result.status), ['pending']);
  finishMute(); await flush();
  assert.equal(f.sent.at(-1).result.status, 'applied');
  assert.equal(f.muted, true); assert.equal(disposed, 1);
  assert.equal(f.c.pending.video, null);
});

test('failed camera restoration after sharing is retried and reports actual publication failure', async () => {
  const f = stage(), c = f.context, camera = track('own-v0', true), desktop = track('own-v1', true);
  camera.mute = () => Promise.resolve(); desktop.dispose = () => Promise.resolve();
  let tries = 0;
  c.room = { removeTrack: () => Promise.resolve(), addTrack: () => { tries++; return Promise.reject(new Error('signaling down')); } };
  c.callJoined = true; c.localVideo = camera; c.localDesktop = desktop; c.shareState = 'on';
  c.people = { local: { local: true, camera, desktop, sharing: true, videoMuted: false } };
  c.stopShare();
  await flush(); await f.advance(1300);
  assert.equal(tries, 3);
  assert.equal(c.videoMuted, true);
  assert.equal(c.shareState, 'idle');
  assert.ok(f.events.some(([, value]) => value.kind === 'camera-failed'));
  c.clearPublicationTasks(); c.clearVideoBindings();
});

test('a late leave completion cannot join an older requested room after a newer switch or hold', async () => {
  const f = stage(), c = f.context, joined = [];
  let left;
  c.room = { leave: () => new Promise(resolve => { left = resolve; }) };
  c.connection = { disconnect() {} };
  c.join = pass => joined.push(pass.room);
  const pass = room => ({ room, domain: 'meet.example.com', xmppDomain: 'meet.example.com' });
  c.switchRoom(pass('two'));
  c.switchRoom(pass('three'));
  await flush();
  assert.deepEqual(joined, []);
  left(); await flush();
  assert.deepEqual(joined, ['three']);
  let leftAgain;
  c.room = { leave: () => new Promise(resolve => { leftAgain = resolve; }) };
  c.switchRoom(pass('four'));
  c.holdRoom();
  leftAgain(); await flush();
  assert.deepEqual(joined, ['three']);
});
