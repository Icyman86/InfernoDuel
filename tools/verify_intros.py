"""Decode and verify all shipped fighter intro videos using FFmpeg/ffprobe."""
from pathlib import Path
import json, subprocess
roster=json.loads(Path('data/fighters.json').read_text())['fighters']
seen=set()
for fighter in roster:
    path=Path(fighter['intro']['video_path'])
    assert path.is_file(), f'Missing intro: {path}'
    result=subprocess.run(['ffprobe','-v','error','-count_frames','-show_streams','-show_format','-of','json',str(path)],capture_output=True,text=True,check=True)
    assert not result.stderr.strip(), result.stderr
    info=json.loads(result.stdout)
    video=next(stream for stream in info['streams'] if stream['codec_type']=='video')
    assert video['codec_name']=='theora' and video['width']==1280 and video['height']==720
    assert int(video['nb_read_frames'])==193, f'Incomplete intro: {path}'
    assert video['avg_frame_rate']=='30/1', f'Unexpected frame rate: {path}'
    assert any(stream['codec_name']=='vorbis' for stream in info['streams'] if stream['codec_type']=='audio')
    assert 6.3<=float(info['format']['duration'])<=6.6
    shots=[]
    for time in ['0.8','3.5']:
        frame=subprocess.run(['ffmpeg','-v','error','-ss',time,'-i',str(path),'-map','0:v:0','-an','-frames:v','1','-f','framemd5','-'],capture_output=True,text=True,check=True)
        assert not frame.stderr.strip(), frame.stderr
        digest=[line for line in frame.stdout.splitlines() if not line.startswith('#')][-1].split(',')[-1].strip()
        shots.append(digest)
    assert shots[0]!=shots[1], f'Close-up and kick do not change: {path}'
    assert tuple(shots) not in seen, f'Reused intro: {path}'
    seen.add(tuple(shots))
    print('PASS',fighter['id'],'193-frame intro decoded, distinct close-up and kick')
print(f'INTRO MEDIA RESULT: {len(seen)} complete distinct intro films verified')
