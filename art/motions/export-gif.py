"""Export all eight motions and review evidence from the native runtime atlases."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

folder = Path(__file__).resolve().parent
root = folder.parent.parent
manifest = json.loads((root / 'assets/spirit-motions.json').read_text())
contact = Image.new('RGB', (1152, len(manifest['motions']) * 240), '#18202c')
labels = ImageDraw.Draw(contact)
for row, name in enumerate(['idle','run','jump','fall','swipe','dash','hurt','death']):
    motion = manifest['motions'][name]
    atlas = Image.open(root / 'assets' / motion['atlas']).convert('RGBA')
    frames = [atlas.crop((i*64, 0, (i+1)*64, 64)) for i in range(len(motion['frames']))]
    palette_source = atlas.convert('RGB').quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    palette = [0,0,0] + palette_source.getpalette()[:765]
    indexed = []
    for rgba in frames:
        quantized = rgba.convert('RGB').quantize(palette=palette_source, dither=Image.Dither.NONE)
        frame = Image.new('P', rgba.size)
        frame.putpalette(palette)
        frame.putdata([v+1 if a else 0 for v,a in zip(quantized.getdata(),rgba.getchannel('A').getdata())])
        indexed.append(frame)
    times = [0]
    for frame in motion['frames']:
        times.append(times[-1] + frame['duration_ms'])
    durations = [round(times[i+1]/10)*10-round(times[i]/10)*10 for i in range(len(frames))]
    # A review-only end hold separates repeated one-shot actions. Runtime holds
    # or exits via state; the restart in a GIF is not a cyclic animation seam.
    if not motion['loop']:
        durations[-1] += 500
    for scale in [1,4]:
        path = folder / f'{name}{"-4x" if scale == 4 else ""}.gif'
        scaled = [f.resize((64*scale,64*scale),Image.Resampling.NEAREST) for f in indexed]
        scaled[0].save(path,save_all=True,append_images=scaled[1:],duration=durations,loop=0,transparency=0,background=0,disposal=2,optimize=False)
        with Image.open(path) as check:
            # GIF may merge identical held poses; compare the decoded timeline.
            elapsed = 0
            for i in range(check.n_frames):
                check.seek(i)
                source = 0
                boundary = durations[0]
                while elapsed >= boundary and source < len(frames)-1:
                    source += 1
                    boundary += durations[source]
                expected = frames[source].resize(check.size,Image.Resampling.NEAREST)
                quantized_expected = indexed[source].convert('RGB').resize(check.size,Image.Resampling.NEAREST)
                actual = check.convert('RGBA')
                assert actual.getchannel('A').tobytes() == expected.getchannel('A').tobytes(), (name,i,'alpha')
                assert all(a[:3] == b for a,b in zip(actual.getdata(),quantized_expected.getdata()) if a[3]), (name,i,'GIF palette')
                elapsed += check.info['duration']
            assert elapsed == sum(durations)
    y = row*240
    labels.text((8,y+5), name.upper() + (' - loop' if motion['loop'] else ' - one shot, final pose held'), fill='#eef0dc')
    sequence = frames + [frames[int(motion.get('loop_from',0))] if motion['loop'] else frames[-1]]
    for i, frame in enumerate(sequence):
        contact.paste(frame.resize((128,128),Image.Resampling.NEAREST),(i*128,y+22),frame.resize((128,128),Image.Resampling.NEAREST))
        contact.paste(frame,(i*128+32,y+172),frame)
        labels.line((i*128+61,y+232,i*128+67,y+232),fill='#70bf85')
        caption = f'{i+1} '+motion['frames'][i]['name'] if i<len(frames) else ('Return' if motion['loop'] else 'Hold')
        labels.text((i*128+3,y+154),caption,fill='#eef0dc')
    print(f'PASS: {name} GIFs at 1x/4x; decoded alpha, shared GIF palette, timing; contact evidence')
contact.save(folder/'contact-sheet.png')
