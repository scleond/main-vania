"""Export the current run atlas as native and 4x looping GIFs (requires Pillow)."""
import json
from pathlib import Path

from PIL import Image

folder = Path(__file__).resolve().parent
spec = json.loads((folder / 'run-poses.json').read_text())
atlas = Image.open(folder.parent.parent / 'assets/spirit-run.png').convert('RGBA')
width, height = spec['cell']
count = len(spec['frames'])
# A common palette prevents frame-to-frame color flicker. Reserve zero for alpha.
palette_image = atlas.convert('RGB').quantize(colors=255, method=Image.Quantize.MEDIANCUT)
palette = [0, 0, 0] + palette_image.getpalette()[:255 * 3]
frames = []
for i in range(count):
    rgba = atlas.crop((i * width, 0, (i + 1) * width, height))
    indexed = rgba.convert('RGB').quantize(palette=palette_image, dither=Image.Dither.NONE)
    frame = Image.new('P', (width, height))
    frame.putpalette(palette)
    frame.putdata([value + 1 if alpha else 0 for value, alpha in zip(indexed.getdata(), rgba.getchannel('A').getdata())])
    frames.append(frame)
# GIF supports centiseconds; distribute rounding so the full cycle stays exact.
boundaries = [round(i * 100 / spec['fps']) for i in range(count + 1)]
durations = [(boundaries[i + 1] - boundaries[i]) * 10 for i in range(count)]
for scale, name in [(1, 'run.gif'), (4, 'run-4x.gif')]:
    output = folder / name
    scaled = [frame.resize((width * scale, height * scale), Image.Resampling.NEAREST) for frame in frames]
    scaled[0].save(output, save_all=True, append_images=scaled[1:], duration=durations, loop=0, transparency=0, background=0, disposal=2, optimize=False)
    with Image.open(output) as check:
        assert check.n_frames == count and check.info['loop'] == 0
        elapsed = 0
        for i in range(count):
            check.seek(i)
            elapsed += check.info['duration']
            actual = check.convert('RGBA')
            expected = atlas.crop((i * width, 0, (i + 1) * width, height)).getchannel('A').resize(actual.size, Image.Resampling.NEAREST)
            assert actual.getchannel('A').tobytes() == expected.tobytes(), f'Alpha/disposal mismatch in frame {i + 1}'
        assert elapsed == boundaries[-1] * 10
    print(f'PASS: {name}, {count} frames, {elapsed} ms, infinite loop, alpha/pivots preserved')
