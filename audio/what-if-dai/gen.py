import json,subprocess,os
chs=json.load(open('lines.json'))
for c,lines in enumerate(chs,1):
    for i,t in enumerate(lines,1):
        out=f"c{c:02d}_{i:02d}.mp3"
        if os.path.exists(out) and os.path.getsize(out)>1000: continue
        body=json.dumps({"text":t,"model_id":"eleven_v3","language_code":"vi","voice_settings":{"stability":0.5}})
        for attempt in range(3):
            code=subprocess.run(["curl","-s","-o",out,"-w","%{http_code}","-X","POST","https://api.elevenlabs.io/v1/text-to-speech/6adFm46eyy74snVn6YrT?output_format=mp3_44100_128","-H","Content-Type: application/json","--data-binary",body],capture_output=True,text=True).stdout
            if code=="200": break
        print(out,code,flush=True)
