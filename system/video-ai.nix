{ pkgs, config, lib, ... }:
let
  videoAIDir = "/mnt/sharefiles/video-ai";

  nvidiaDriver = config.hardware.nvidia.package; # nvidia-smi

  # Binários que os scripts precisam no PATH (self-contained, sem nix-shell).
  toolPath = lib.makeBinPath (with pkgs; [
    python312
    ffmpeg-full
    git
    wget
    nvidiaDriver
  ]);

  # Envolve cada script com o ambiente necessário (PATH + driver CUDA + HOME).
  mkScript = name: text: pkgs.writeShellScriptBin name ''
    export PATH=${toolPath}:$PATH
    export LD_LIBRARY_PATH=/run/opengl-driver/lib
    export TORCH_CUDA_ARCH_LIST=8.9
    export VIDEO_AI_HOME=''${VIDEO_AI_HOME:-${videoAIDir}}
    ${text}
  '';

  bootstrap = mkScript "video_ai_bootstrap" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    mkdir -p "$BASE"/{venvs,src,models,output}

    if [ ! -d "$BASE/venvs/comfy" ]; then
      echo ">> criando venv comfy..."
      python3 -m venv "$BASE/venvs/comfy"
      "$BASE/venvs/comfy/bin/pip" install -U pip wheel setuptools
      "$BASE/venvs/comfy/bin/pip" install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu128
    fi
    if [ ! -d "$BASE/src/ComfyUI" ]; then
      echo ">> clonando ComfyUI..."
      git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git "$BASE/src/ComfyUI"
    fi
    "$BASE/venvs/comfy/bin/pip" install -r "$BASE/src/ComfyUI/requirements.txt"

    # symlink dos modelos (usado pelo serviço comfyui)
    mkdir -p "$BASE/models/comfyui"
    [ -e "$BASE/src/ComfyUI/models" ] || ln -s "$BASE/models/comfyui" "$BASE/src/ComfyUI/models"

    if [ ! -d "$BASE/venvs/tts" ]; then
      echo ">> criando venv tts..."
      python3 -m venv "$BASE/venvs/tts"
      "$BASE/venvs/tts/bin/pip" install -U pip
      "$BASE/venvs/tts/bin/pip" install git+https://github.com/resemble-ai/chatterbox.git
    fi

    if [ ! -d "$BASE/venvs/whisper" ]; then
      echo ">> criando venv whisper..."
      python3 -m venv "$BASE/venvs/whisper"
      "$BASE/venvs/whisper/bin/pip" install -U pip
      "$BASE/venvs/whisper/bin/pip" install faster-whisper
    fi

    echo ">> bootstrap OK em $BASE"
    echo ">> próximo: video_ai_download_models"
  '';

  check = mkScript "video_ai_check" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    echo "== nvidia-smi =="
    nvidia-smi
    echo
    echo "== torch =="
    "$BASE/venvs/comfy/bin/python" -c \
      'import torch; print("torch", torch.__version__, "| cuda", torch.cuda.is_available());
       print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else "SEM GPU")'
  '';

  downloadModels = mkScript "video_ai_download_models" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    HF="https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B/resolve/main"
    M="$BASE/models/comfyui"
    mkdir -p "$M"/{diffusion_models,text_encoders,vae,clip}

    dl() { wget -c -O "$2" "$HF/$1"; }

    echo ">> baixando Wan 2.2 TI2V-5B (~30 GB, pode demorar)..."
    dl high_noise_720p/wan2.2_ti2v_5B_high_noise_720p.safetensors \
       "$M/diffusion_models/wan2.2_ti2v_5B_high_noise_720p.safetensors"
    dl low_noise_720p/wan2.2_ti2v_5B_low_noise_720p.safetensors \
       "$M/diffusion_models/wan2.2_ti2v_5B_low_noise_720p.safetensors"
    dl models_t5_umt5-xxl-enc-bf16.pth \
       "$M/text_encoders/models_t5_umt5-xxl-enc-bf16.pth"
    dl Wan2.2_VAE.pth \
       "$M/vae/Wan2.2_VAE.pth"
    dl models_clip_open-clip-xlm-roberta-large-vit-huge-14.pth \
       "$M/clip/models_clip_open-clip-xlm-roberta-large-vit-huge-14.pth"

    echo ">> modelos em $M"
    echo ">> (se algum wget der 404, confira os nomes em https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B/tree/main)"
  '';

  narrate = mkScript "video_ai_narrate" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    [ "$#" -ge 2 ] || { echo "uso: video_ai_narrate roteiro.txt narracao.wav [referencia.wav]"; exit 1; }
    TEXT="$1"; OUT="$2"; REF="''${3:-}"
    exec "$BASE/venvs/tts/bin/python" - "$TEXT" "$OUT" "$REF" <<'PY'
import sys
import soundfile as sf
from chatterbox.tts import ChatterboxTTS
text, out, ref = sys.argv[1], sys.argv[2], sys.argv[3]
model = ChatterboxTTS.from_pretrained(device="cuda")
wav = model.generate(text, audio_prompt_path=ref if ref else None)
sf.write(out, wav, model.sr)
print(f"narracao salva em {out}")
PY
  '';

  subtitles = mkScript "video_ai_subtitles" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    [ "$#" -ge 2 ] || { echo "uso: video_ai_subtitles narracao.wav legenda.srt"; exit 1; }
    AUD="$1"; SRT="$2"
    exec "$BASE/venvs/whisper/bin/python" - "$AUD" "$SRT" <<'PY'
import sys
from faster_whisper import WhisperModel
aud, srt = sys.argv[1], sys.argv[2]
# "small" é um bom custo/benefício p/ PT-BR em CPU int8; use "medium" p/ mais acurácia.
model = WhisperModel("small", device="cpu", compute_type="int8")
segments, info = model.transcribe(aud, language="pt")
def ts(t):
    h = int(t // 3600); m = int(t % 3600 // 60); s = int(t % 60); ms = int((t - int(t)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"
with open(srt, "w") as f:
    for i, seg in enumerate(segments, 1):
        f.write(f"{i}\n{ts(seg.start)} --> {ts(seg.end)}\n{seg.text.strip()}\n\n")
print(f"legenda em {srt}")
PY
  '';

  burn = mkScript "video_ai_burn" ''
    set -euo pipefail
    [ "$#" -eq 4 ] || { echo "uso: video_ai_burn video_sem_audio.mp4 narracao.wav legenda.srt video_final.mp4"; exit 1; }
    VID="$1"; AUD="$2"; SRT="$3"; OUT="$4"

    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q nvenc; then
      VC="h264_nvenc"; VOPTS=(-preset p7 -cq 17)
    else
      VC="libx264";     VOPTS=(-preset slow -crf 17)
    fi

    # subtitles= exige libass (ffmpeg-full tem). Caminhos com espaço/': ' quebram o filtro — evite.
    ffmpeg -y \
      -i "$VID" -i "$AUD" \
      -filter_complex "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,subtitles=$SRT[v];[1:a]loudnorm=I=-16:TP=-1.5:LRA=11[a]" \
      -map "[v]" -map "[a]" \
      -c:v "$VC" "''${VOPTS[@]}" \
      -c:a aac -b:a 192k -shortest \
      "$OUT"
    echo ">> final em $OUT"
  '';
in
{
  environment.systemPackages = [ bootstrap check downloadModels narrate subtitles burn ];

  # usuário do serviço + grupo p/ compartilhar /mnt/sharefiles/video-ai
  users.users.videoai = {
    isSystemUser = true;
    group = "videoai";
  };
  users.groups.videoai = {
    # mantenha em sincronia com alunos.nix
    members = [
      "zimacube"
      "medina"
      "aluno0549-6"
      "aluno202512120026"
      "aluno202412220014"
      "aluno20211210030"
      "aluno202412120031"
      "aluno521-5"
      "alunoccemanuel"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${videoAIDir} 2775 root videoai -"
    "d ${videoAIDir}/models 2775 root videoai -"
    "d ${videoAIDir}/venvs 2775 root videoai -"
    "d ${videoAIDir}/output 2775 root videoai -"
  ];

  # ComfyUI sempre no ar em 8188 (acessível no navegador, como os Shiny).
  # Fica reiniciando até o admin rodar video_ai_bootstrap + video_ai_download_models.
  systemd.services.comfyui = {
    description = "ComfyUI (Wan 2.2 TI2V-5B)";
    after = [ "network.target" "remote-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "videoai";
      Group = "videoai";
      WorkingDirectory = "${videoAIDir}/src/ComfyUI";
      ExecStart = "${videoAIDir}/venvs/comfy/bin/python main.py --listen 0.0.0.0 --port 8188";
      Environment = [
        "LD_LIBRARY_PATH=/run/opengl-driver/lib"
        "TORCH_CUDA_ARCH_LIST=8.9"
      ];
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
