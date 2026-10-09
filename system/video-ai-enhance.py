import cv2, sys, os
sys.path.insert(0, '/mnt/sharefiles/video-ai/src/GFPGAN')
os.chdir('/mnt/sharefiles/video-ai/src/GFPGAN')
from gfpgan import GFPGANer

in_v, out_v = sys.argv[1], sys.argv[2]
restorer = GFPGANer(
    model_path='experiments/weights/GFPGANv1.4.pth',
    upscale=1, arch='clean', channel_multiplier=2, device='cpu')

cap = cv2.VideoCapture(in_v)
fps = cap.get(cv2.CAP_PROP_FPS)
w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
writer = cv2.VideoWriter(out_v, cv2.VideoWriter_fourcc(*'mp4v'), fps, (w, h))

i = 0
while True:
    ret, frame = cap.read()
    if not ret:
        break
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    _, _, restored = restorer.enhance(rgb, has_aligned=False, only_center_face=True, paste_back=True, weight=0.5)
    if restored is None:
        restored = rgb
    writer.write(cv2.cvtColor(restored, cv2.COLOR_RGB2BGR))
    i += 1
    if i % 8 == 0:
        print(f'{i} frames processados', flush=True)

cap.release()
writer.release()
print(f'DONE: {i} frames -> {out_v}')
