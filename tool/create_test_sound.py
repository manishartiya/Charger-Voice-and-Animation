import wave, math, struct
from pathlib import Path
path=Path('docs/device/chargevoice-test.wav')
with wave.open(str(path),'wb') as f:
    f.setparams((1,2,16000,0,'NONE','not compressed'))
    f.writeframes(b''.join(struct.pack('<h',int(1200*math.sin(2*math.pi*440*n/16000)*min(1,n/1600)*min(1,(16*16000-n)/1600))) for n in range(16*16000)))
