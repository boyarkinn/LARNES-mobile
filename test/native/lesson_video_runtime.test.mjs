import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import { test } from 'node:test';

const html = readFileSync(new URL('../../assets/call/lesson_call_stage.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const flush = async () => { for (let i = 0; i < 10; i++) await Promise.resolve(); };
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
    people = { child: {id:'child',name:'Child'}, observer:{id:'observer',name:'Teacher observer'}, teacher:{id:'teacher',name:'Teacher'} };
    localEndpoint='child';`, c);
  assert.deepEqual([...c.orderedPeople()].map(p => p.id), ['teacher', 'child']);
  const command = { target: 'child', device: 'video', muted: true, sentAt: 100001 };
  assert.equal(c.decideCommand(command, 'observer'), 'apply');
  assert.equal(c.decideCommand({ ...command, target: 'someone-else' }, 'observer'), 'drop');
  assert.equal(c.decideCommand(command, 'stranger'), 'drop');
  assert.equal(c.knownTeacher('observer'), false);
  assert.deepEqual([...c.teacherIds], ['teacher']);
  await f.advance(5001);
  assert.equal(c.decideCommand(command, 'observer'), 'drop');
  assert.equal(c.decideCommand(command, 'teacher'), 'apply');
  vm.runInContext(`setTeachers(['teacher'], 'teacher', ['teacher','observer'], ['observer'])`, c);
  assert.equal(c.decideCommand(command, 'observer'), 'apply');
  vm.runInContext(`setTeachers(['teacher'],'teacher')`, c);
  assert.equal(c.decideCommand(command, 'observer'), 'drop');
  assert.equal(c.observerParticipant({ getIdentity: () => ({ user: { id: 'observer:teacher-1' } }) }), true);
  assert.equal(c.observerParticipant({ getIdentity: () => ({ user: { id: 'teacher:teacher-1' } }) }), false);
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
  assert.deepEqual(joined, ['three']);
  left(); await flush();
  assert.deepEqual(joined, ['three']);
  let leftAgain;
  c.room = { leave: () => new Promise(resolve => { leftAgain = resolve; }) };
  c.switchRoom(pass('four'));
  c.holdRoom();
  leftAgain(); await flush();
  assert.deepEqual(joined, ['three']);
});
