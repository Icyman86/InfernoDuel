import ctypes as C, os, subprocess, time, re
from pathlib import Path
from PIL import ImageGrab, Image
out=Path('/workspace/.runtime/native-v8-smoke');out.mkdir(exist_ok=True)
x=C.CDLL('libX11.so.6'); xt=C.CDLL('libXtst.so.6')
x.XOpenDisplay.argtypes=[C.c_char_p];x.XOpenDisplay.restype=C.c_void_p
x.XDefaultRootWindow.argtypes=[C.c_void_p];x.XDefaultRootWindow.restype=C.c_ulong
x.XQueryTree.argtypes=[C.c_void_p,C.c_ulong,C.POINTER(C.c_ulong),C.POINTER(C.c_ulong),C.POINTER(C.POINTER(C.c_ulong)),C.POINTER(C.c_uint)]
x.XFetchName.argtypes=[C.c_void_p,C.c_ulong,C.POINTER(C.c_char_p)]
x.XFree.argtypes=[C.c_void_p];x.XFlush.argtypes=[C.c_void_p]
x.XStringToKeysym.argtypes=[C.c_char_p];x.XStringToKeysym.restype=C.c_ulong
x.XKeysymToKeycode.argtypes=[C.c_void_p,C.c_ulong];x.XKeysymToKeycode.restype=C.c_uint
x.XSetInputFocus.argtypes=[C.c_void_p,C.c_ulong,C.c_int,C.c_ulong]
x.XRaiseWindow.argtypes=[C.c_void_p,C.c_ulong]
xt.XTestFakeKeyEvent.argtypes=[C.c_void_p,C.c_uint,C.c_int,C.c_ulong]
d=x.XOpenDisplay(b':99');assert d,'X11 display unavailable'
root=x.XDefaultRootWindow(d)
def windows():
 r=C.c_ulong();p=C.c_ulong();children=C.POINTER(C.c_ulong)();count=C.c_uint()
 x.XQueryTree(d,root,C.byref(r),C.byref(p),C.byref(children),C.byref(count))
 result=[]
 for i in range(count.value):
  name=C.c_char_p();w=children[i]
  if x.XFetchName(d,w,C.byref(name)) and name.value:
   if b'Inferno Duel' in name.value: result.append(w)
   x.XFree(name)
 if children:x.XFree(children)
 return result
before=set(windows())
log=(out/'engine.log').open('w')
process=subprocess.Popen(['./builds/linux/PLAY.sh','--audio-driver','Dummy'],cwd='/workspace/InfernoDuel',stdout=log,stderr=subprocess.STDOUT)
def key(name,down=None):
 code=x.XKeysymToKeycode(d,x.XStringToKeysym(name.encode()))
 for state in ([True,False] if down is None else [down]):
  xt.XTestFakeKeyEvent(d,code,int(state),0);x.XFlush(d);time.sleep(.06)
def capture(name):
 path=out/(name+'.png');ImageGrab.grab(xdisplay=':99').save(path)
 result=subprocess.run(['tesseract',str(path),'stdout'],capture_output=True,text=True,check=True)
 (out/(name+'.txt')).write_text(result.stdout)
 return result.stdout
def wait_for(name,predicate,timeout=15):
 deadline=time.monotonic()+timeout
 while time.monotonic()<deadline:
  text=capture(name)
  if predicate(text.upper()):return text
  assert process.poll() is None,'Native engine exited during '+name
  time.sleep(.2)
 raise AssertionError('Timed out waiting for rendered '+name)
try:
 deadline=time.monotonic()+15
 while time.monotonic()<deadline:
  found=[w for w in windows() if w not in before]
  if found:break
  assert process.poll() is None,'Native engine exited before its window opened'
  time.sleep(.1)
 else:raise AssertionError('Native game window not found')
 x.XRaiseWindow(d,found[0]);x.XSetInputFocus(d,found[0],2,0);x.XFlush(d)
 time.sleep(1)
 assert 'INFERNO' in capture('menu').upper(),'Native menu did not render'
 for i in range(4):key('s')
 key('f');time.sleep(.7)
 text=capture('gallery')
 assert 'FIGHTERS' in text.upper(),'Native character showcase did not open'
 print('PASS native release-engine + PCK menu and character showcase render',flush=True)
 key('Escape')
 wait_for('menu-return',lambda t:'LOCAL VERSUS' in t)
 key('f')
 wait_for('select',lambda t:'CHOOSE YOUR FIGHTER' in t)
 key('f');key('i')
 wait_for('arena',lambda t:'INFERNAL CITADEL' in t and '60 SECONDS' in t)
 key('Return')
 wait_for('fight-active',lambda t:'SHARKBYTE' in t and 'BULLET' in t and re.search(r'\b5[0-9]\b',t))
 key('d',True);key('Left',True);time.sleep(.7);key('d',False);key('Left',False)
 key('f',True);key('i',True);time.sleep(.08);key('f',False);key('i',False);time.sleep(.2)
 text=capture('fight')
 # Names and active timer were already verified by wait_for before input.
 # Whole-screen OCR can omit the HUD when overlapping fighters dominate the frame.
 image=Image.open(out/'fight.png').convert('RGB')
 assert sum(image.getpixel((760,75))) < 200 or sum(image.getpixel((520,75))) < 200,'Native attacks did not reduce health bars'
 print('PASS native keyboard select/fight and attacks apply visible damage',flush=True)
 key('Escape');time.sleep(.2)
 assert 'PAUSED' in capture('pause').upper(),'Native pause did not open'
 print('PASS native pause renders',flush=True)
 # Navigate from pause to menu, then use the actual Quit confirmation.
 for i in range(3):key('s')
 key('f');time.sleep(.2);key('Return');time.sleep(.3)
 key('w');key('f');time.sleep(.2);key('Return')
 result=process.wait(timeout=10)
 assert result==0,f'Native exit status {result}'
 log.close()
 assert not re.search(r'SCRIPT ERROR|^ERROR:|instances leaked',(out/'engine.log').read_text(),re.M),'Engine errors in native package'
 print('NATIVE PACKAGE RESULT: workflow passed, normal exit 0, no engine/script errors',flush=True)
finally:
 if process.poll() is None:
  process.terminate()
  try:process.wait(timeout=5)
  except subprocess.TimeoutExpired:process.kill()
 log.close()
