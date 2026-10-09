{ pkgs, config, lib, ... }:
let
  videoAIDir = "/mnt/sharefiles/video-ai";

  nvidiaDriver = config.hardware.nvidia.package; # nvidia-smi

  # Libs de runtime p/ binários Linux genéricos (pip wheels, piper, wav2lip).
  runtimeLibs = lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.bzip2 pkgs.xz pkgs.libsndfile nvidiaDriver ];

  # Binários que os scripts precisam no PATH (self-contained, sem nix-shell).
  toolPath = lib.makeBinPath (with pkgs; [
    python312
    ffmpeg-full
    git
    wget
    nvidiaDriver
  ]);

  # Envolve cada script com o ambiente necessário (PATH + libs + HOME).
  mkScript = name: text: pkgs.writeShellScriptBin name ''
    export PATH=${toolPath}:$PATH
    export LD_LIBRARY_PATH=${runtimeLibs}
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
    # o serviço roda como videoai: garante escrita no clone (user/, models/)
    chgrp -R videoai "$BASE/src/ComfyUI" 2>/dev/null || true
    chmod -R g+w "$BASE/src/ComfyUI" 2>/dev/null || true
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

    # ---- Wav2Lip (lip sync) ----
    if [ ! -d "$BASE/venvs/wav2lip" ]; then
      echo ">> criando venv wav2lip..."
      python3 -m venv "$BASE/venvs/wav2lip"
      "$BASE/venvs/wav2lip/bin/pip" install -U pip
      "$BASE/venvs/wav2lip/bin/pip" install torch --index-url https://download.pytorch.org/whl/cpu
      "$BASE/venvs/wav2lip/bin/pip" install opencv-python-headless librosa numpy tqdm numba soundfile
    fi
    if [ ! -d "$BASE/src/Wav2Lip" ]; then
      echo ">> clonando Wav2Lip..."
      git clone --depth 1 https://github.com/Rudrabha/Wav2Lip.git "$BASE/src/Wav2Lip"
      # compat com librosa novo (API mudou)
      sed -i 's/^import librosa$/import librosa\nimport soundfile as sf/' "$BASE/src/Wav2Lip/audio.py"
      sed -i 's/librosa\.core\.load/librosa.load/' "$BASE/src/Wav2Lip/audio.py"
      sed -i 's/librosa\.output\.write_wav(path, wav, sr=sr)/sf.write(path, wav, sr)/' "$BASE/src/Wav2Lip/audio.py"
      sed -i 's/librosa\.filters\.mel(hp\.sample_rate, hp\.n_fft, n_mels=hp\.num_mels,/librosa.filters.mel(sr=hp.sample_rate, n_fft=hp.n_fft, n_mels=hp.num_mels,/' "$BASE/src/Wav2Lip/audio.py"
    fi
    mkdir -p "$BASE/src/Wav2Lip/checkpoints" "$BASE/src/Wav2Lip/face_detection/detection/sfd"
    if [ ! -f "$BASE/src/Wav2Lip/checkpoints/wav2lip_gan.pth" ]; then
      echo ">> baixando wav2lip_gan.pth..."
      wget -c -O "$BASE/src/Wav2Lip/checkpoints/wav2lip_gan.pth" "https://huggingface.co/Nekochu/Wav2Lip/resolve/main/wav2lip_gan.pth"
    fi
    if [ ! -f "$BASE/src/Wav2Lip/face_detection/detection/sfd/s3fd.pth" ]; then
      wget -c -O "$BASE/src/Wav2Lip/face_detection/detection/sfd/s3fd.pth" "https://huggingface.co/camenduru/Wav2Lip/resolve/main/face_detection/detection/sfd/s3fd.pth"
    fi

    # ---- Piper (TTS PT-BR) ----
    if [ ! -f "$BASE/tools/piper/piper" ]; then
      echo ">> baixando piper (binário)..."
      mkdir -p "$BASE/tools"
      wget -c -O /tmp/piper.tar.gz "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz"
      tar xzf /tmp/piper.tar.gz -C "$BASE/tools"
    fi
    if [ ! -f "$BASE/models/piper/pt_BR-faber-medium.onnx" ]; then
      echo ">> baixando voz piper pt_BR..."
      mkdir -p "$BASE/models/piper"
      wget -c -O "$BASE/models/piper/pt_BR-faber-medium.onnx" "https://huggingface.co/rhasspy/piper-voices/resolve/main/pt/pt_BR/faber/medium/pt_BR-faber-medium.onnx"
      wget -c -O "$BASE/models/piper/pt_BR-faber-medium.onnx.json" "https://huggingface.co/rhasspy/piper-voices/resolve/main/pt/pt_BR/faber/medium/pt_BR-faber-medium.onnx.json"
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
    HF="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files"
    M="$BASE/models/comfyui"
    mkdir -p "$M/diffusion_models" "$M/text_encoders" "$M/vae"

    dl() { wget -c -O "$2" "$HF/$1"; }

    echo ">> baixando Wan 2.2 TI2V-5B (formato ComfyUI, ~18 GB, pode demorar)..."
    dl diffusion_models/wan2.2_ti2v_5B_fp16.safetensors \
       "$M/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors"
    dl text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
       "$M/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    dl vae/wan2.2_vae.safetensors \
       "$M/vae/wan2.2_vae.safetensors"

    echo ">> modelos em $M"
    echo ">> no ComfyUI: UNETLoader -> wan2.2_ti2v_5B_fp16, CLIPLoader(tipo wan) -> umt5_xxl_fp8, VAE -> wan2.2_vae"
  '';

  narrate = mkScript "video_ai_narrate" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    [ "$#" -ge 2 ] || { echo "uso: video_ai_narrate roteiro.txt narracao.wav [referencia.wav]"; exit 1; }
    TEXT=$(cat "$1"); OUT="$2"; REF="''${3:-}"
    exec "$BASE/venvs/tts/bin/python" - "$TEXT" "$OUT" "$REF" <<'PY'
import sys
import soundfile as sf
from chatterbox.tts import ChatterboxTTS
text, out, ref = sys.argv[1], sys.argv[2], sys.argv[3]
model = ChatterboxTTS.from_pretrained(device="cuda")
wav = model.generate(text, audio_prompt_path=ref if ref else None)
sf.write(out, wav.squeeze(0).cpu().numpy(), model.sr)
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

  narratePt = mkScript "video_ai_narrate_pt" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    [ "$#" -ge 2 ] || { echo "uso: video_ai_narrate_pt texto.txt saida.wav"; exit 1; }
    TEXT_FILE="$1"; OUT="$2"
    VOICE="$BASE/models/piper/pt_BR-faber-medium.onnx"
    cd "$BASE/tools/piper"
    LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH ./piper --model "$VOICE" --output_file "$OUT" < "$TEXT_FILE"
    echo ">> narração PT-BR em $OUT"
  '';

  lipsync = mkScript "video_ai_lipsync" ''
    set -euo pipefail
    BASE="$VIDEO_AI_HOME"
    [ "$#" -eq 3 ] || { echo "uso: video_ai_lipsync video.mp4 audio.wav saida.mp4"; exit 1; }
    VID="$1"; AUD="$2"; OUT="$3"
    cd "$BASE/src/Wav2Lip"
    "$BASE/venvs/wav2lip/bin/python" inference.py \
      --checkpoint_path checkpoints/wav2lip_gan.pth \
      --face "$VID" --audio "$AUD" --outfile "$OUT"
    echo ">> lip sync em $OUT"
  '';
in
{
  environment.systemPackages = [ bootstrap check downloadModels narrate narratePt subtitles burn lipsync ];

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
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${nvidiaDriver}/lib"
        "TORCH_CUDA_ARCH_LIST=8.9"
      ];
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
