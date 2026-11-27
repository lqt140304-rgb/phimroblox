import json,subprocess,os
from plan import SFX
chs=json.load(open('lines.json'))
def dur(f): return float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",f],capture_output=True,text=True).stdout)
GAP=0.3
outs=[]
for c in range(1,len(chs)+1):
    starts=[];t=0
    for i in range(1,len(chs[c-1])+1):
        starts.append(t); t+=round(dur(f"c{c:02d}_{i:02d}.mp3")+GAP,2)
    total=t
    inputs=["-i",f"CHUONG-{c:02d}.mp3"]; fc=[]; labels=[]
    mus=f"music/c{c:02d}.mp3"
    has_m=os.path.exists(mus)
    if has_m:
        inputs+=["-i",mus]
        fc.append(f"[1:a]aformat=channel_layouts=stereo,atrim=0:{total+0.6},afade=t=in:d=1,afade=t=out:st={max(0,total-1)}:d=1.5,volume=0.42[m]")
    k=len(inputs)//2
    for (n,line,off,name,_,_,vol) in SFX:
        if n!=c: continue
        f=f"sfx/c{n:02d}_{name}.mp3"
        if not os.path.exists(f): continue
        ms=int((starts[line-1]+off)*1000)
        inputs+=["-i",f]
        fc.append(f"[{k}:a]aformat=channel_layouts=stereo,volume={vol},adelay={ms}|{ms}[s{k}]"); labels.append(f"[s{k}]"); k+=1
    fc.append("[0:a]aformat=channel_layouts=stereo,asplit=3[v][sc1][sc2]")
    mixin=["[v]"]
    if has_m:
        fc.append("[m][sc1]sidechaincompress=threshold=0.03:ratio=6:attack=20:release=400[md]"); mixin.append("[md]")
    else:
        fc.append("[sc1]anullsink")
    if labels:
        fc.append("".join(labels)+f"amix=inputs={len(labels)}:duration=longest:normalize=0[sx]")
        fc.append("[sx][sc2]sidechaincompress=threshold=0.05:ratio=3:attack=20:release=300[sd]"); mixin.append("[sd]")
    else:
        fc.append("[sc2]anullsink")
    fc.append("".join(mixin)+f"amix=inputs={len(mixin)}:duration=first:normalize=0,alimiter=limit=0.95[out]")
    out=f"CHUONG-{c:02d}-HOAN-CHINH.mp3"
    r=subprocess.run(["ffmpeg","-y","-v","error"]+inputs+["-filter_complex",";".join(fc),"-map","[out]","-b:a","192k",out],capture_output=True,text=True)
    if r.returncode: print(c,r.stderr[-300:])
    outs.append(out)
subprocess.run(["ffmpeg","-y","-v","error","-f","lavfi","-i","anullsrc=r=44100:cl=stereo","-t","0.6","-b:a","192k","gap.mp3"])
with open("list.txt","w") as f:
    f.write("file 'gap.mp3'\n")
    for o in outs: f.write(f"file '{o}'\nfile 'gap.mp3'\n")
subprocess.run(["ffmpeg","-y","-v","error","-f","concat","-safe","0","-i","list.txt","-b:a","192k","BAN-DAI-HOAN-CHINH.mp3"])
os.remove("list.txt"); os.remove("gap.mp3")
print("full", round(dur("BAN-DAI-HOAN-CHINH.mp3")/60,2),"min")
