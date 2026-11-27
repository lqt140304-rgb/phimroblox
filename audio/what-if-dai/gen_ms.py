import json,subprocess,os
from plan import MUSIC,SFX
def dur(f): return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",f],capture_output=True,text=True).stdout or 0)
def post(url,body,out):
    for _ in range(3):
        code=subprocess.run(["curl","-s","-m","300","-o",out,"-w","%{http_code}","-X","POST",url,"-H","Content-Type: application/json","--data-binary",json.dumps(body)],capture_output=True,text=True).stdout
        if code=="200": return code
    return code
for c,(n,_,_,name,text,d,_) in [(x[0],x) for x in SFX]:
    out=f"sfx/c{n:02d}_{name}.mp3"
    if os.path.exists(out) and os.path.getsize(out)>1000: continue
    print(out,post("https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128",{"text":text,"duration_seconds":d,"prompt_influence":0.5},out),flush=True)
for c,mood in MUSIC.items():
    out=f"music/c{c:02d}.mp3"
    if os.path.exists(out) and os.path.getsize(out)>1000: continue
    L=dur(f"CHUONG-{c:02d}.mp3")+1.5
    prompt=f"Instrumental background music for a YouTube science explainer chapter, no vocals. Mood: {mood}. Mixed quietly to sit under a narrator, smooth fade in and fade out."
    print(out,post("https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",{"prompt":prompt,"music_length_ms":int(L*1000),"force_instrumental":True},out),flush=True)
