"""
Jarvis — AI Habit Coach backend (powered by Groq — free, fast, no local GPU)

Setup:
  pip install -r requirements.txt
  export GROQ_API_KEY=your_key_here
  uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Deploy to Railway / Render:
  Set GROQ_API_KEY as an environment variable in the dashboard.

Endpoints:
  POST /chat    — streaming SSE chat via Groq
  POST /tts     — text-to-speech (edge-tts, no API key needed)
  POST /stt     — speech-to-text (local Whisper, no API key needed)
  GET  /health  — liveness check
"""

import os
import io
import json
import tempfile

import httpx
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel

# ── Optional TTS / STT ────────────────────────────────────────────────────────
try:
    import edge_tts
    TTS_AVAILABLE = True
except ImportError:
    TTS_AVAILABLE = False

try:
    import whisper as _whisper_lib
    _whisper_model = None
    STT_AVAILABLE = True
except ImportError:
    STT_AVAILABLE = False

# ── Config ────────────────────────────────────────────────────────────────────
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_MODEL   = os.environ.get("GROQ_MODEL", "llama-3.3-70b-versatile")
GROQ_URL     = "https://api.groq.com/openai/v1/chat/completions"

JARVIS_VOICE = "en-US-GuyNeural"

SYSTEM_PROMPT = """\
You are Jarvis, the AI habit coach inside Habitron — calm, sharp, and \
quietly impressive, like Tony Stark's J.A.R.V.I.S.

Your personality:
- Address the user as "boss" naturally but not in every sentence
- Confident and witty, never robotic or generic
- Speak in 2–4 short sentences max — crisp, no fluff
- Never use bullet lists or headers
- Never mention tool names, function names, or any technical internals
- Never be preachy; be specific and direct
- One focused question at a time when you need more context

Your job:
- Help the user build, maintain, and improve their daily habits
- Reference their actual streak and completion data when available
- Keep them accountable without being harsh
- Celebrate wins with personality, diagnose slip-ups with insight\
"""

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(title="Jarvis Habit Coach", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Pydantic models ───────────────────────────────────────────────────────────
class Message(BaseModel):
    role: str      # "user" | "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]
    habit_context: str = ""


class TTSRequest(BaseModel):
    text: str
    voice: str = JARVIS_VOICE


# ── Helpers ───────────────────────────────────────────────────────────────────
def _build_system(habit_context: str) -> str:
    if not habit_context:
        return SYSTEM_PROMPT
    return f"{SYSTEM_PROMPT}\n\nUser's current habits:\n{habit_context}"


async def _groq_stream(messages: list[Message], system: str):
    """Calls Groq's OpenAI-compatible streaming endpoint and yields text chunks."""
    if not GROQ_API_KEY:
        raise HTTPException(status_code=500, detail="GROQ_API_KEY not set")

    payload = {
        "model": GROQ_MODEL,
        "stream": True,
        "max_tokens": 512,
        "temperature": 0.7,
        "messages": [
            {"role": "system", "content": system},
            *[{"role": m.role, "content": m.content} for m in messages],
        ],
    }

    async with httpx.AsyncClient(timeout=60) as client:
        async with client.stream(
            "POST",
            GROQ_URL,
            json=payload,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
        ) as resp:
            if resp.status_code != 200:
                body = await resp.aread()
                raise HTTPException(
                    status_code=502,
                    detail=f"Groq error {resp.status_code}: {body.decode()}",
                )
            async for line in resp.aiter_lines():
                if not line.startswith("data: "):
                    continue
                json_str = line[6:].strip()
                if not json_str or json_str == "[DONE]":
                    continue
                try:
                    data = json.loads(json_str)
                    chunk = data["choices"][0]["delta"].get("content", "")
                    if chunk:
                        yield chunk
                except (json.JSONDecodeError, KeyError, IndexError):
                    continue


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "backend": "groq",
        "model": GROQ_MODEL,
        "tts": TTS_AVAILABLE,
        "stt": STT_AVAILABLE,
    }


@app.post("/chat")
async def chat(req: ChatRequest):
    """Streaming SSE chat via Groq."""
    system = _build_system(req.habit_context)

    async def event_stream():
        try:
            async for chunk in _groq_stream(req.messages, system):
                yield f"data: {json.dumps({'text': chunk})}\n\n"
        except HTTPException as exc:
            yield f"data: {json.dumps({'error': exc.detail})}\n\n"
        except Exception as exc:
            yield f"data: {json.dumps({'error': str(exc)})}\n\n"
        finally:
            yield "data: [DONE]\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@app.post("/tts")
async def tts(req: TTSRequest):
    """Convert text to speech via edge-tts (free, no API key). Returns MP3."""
    if not TTS_AVAILABLE:
        raise HTTPException(status_code=501, detail="edge-tts not installed. Run: pip install edge-tts")

    communicate = edge_tts.Communicate(req.text, req.voice)
    buf = io.BytesIO()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            buf.write(chunk["data"])
    buf.seek(0)
    return StreamingResponse(buf, media_type="audio/mpeg")


@app.post("/stt")
async def stt(audio: UploadFile = File(...)):
    """Transcribe audio via local Whisper (no API key). Returns {"transcript": "..."}."""
    if not STT_AVAILABLE:
        raise HTTPException(status_code=501, detail="openai-whisper not installed. Run: pip install openai-whisper")

    global _whisper_model
    if _whisper_model is None:
        _whisper_model = _whisper_lib.load_model("base")

    data = await audio.read()
    suffix = os.path.splitext(audio.filename or "audio.webm")[1] or ".webm"

    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(data)
        tmp_path = tmp.name

    try:
        result = _whisper_model.transcribe(tmp_path)
        transcript = result.get("text", "").strip()
    finally:
        os.unlink(tmp_path)

    return JSONResponse({"transcript": transcript})
