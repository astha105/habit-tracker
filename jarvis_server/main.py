"""
Jarvis — AI Habit Coach backend (powered by Ollama, 100% free & local)
FastAPI server that powers the Jarvis chat experience in Habitron.

Requirements:
  1. Install Ollama → https://ollama.com/download
  2. Pull a model  → ollama pull llama3.2
  3. Run this server:
       pip install -r requirements.txt
       uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Endpoints:
  POST /chat    — streaming SSE chat
  POST /tts     — text-to-speech (returns MP3, needs edge-tts)
  POST /stt     — speech-to-text  (needs openai-whisper)
  GET  /health  — liveness + capability check
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
    _whisper_model = None        # lazy-loaded on first /stt call
    STT_AVAILABLE = True
except ImportError:
    STT_AVAILABLE = False

# ── Config ────────────────────────────────────────────────────────────────────
OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL    = os.environ.get("OLLAMA_MODEL", "llama3.2:1b")

JARVIS_VOICE    = "en-US-GuyNeural"                             # edge-tts voice

SYSTEM_PROMPT = """\
You are Jarvis, an intelligent and motivating personal habit coach inside a \
habit-tracking app called Habitron.

Your personality:
- Direct, warm, and insightful — like a knowledgeable mentor who genuinely cares
- Never generic or preachy; always specific to the user's actual habits
- Concise by default (under 100 words) unless asked for detail
- Never use bullet lists unless the user explicitly asks
- Ask one focused question at a time when you need more context

Your job:
- Help users build, maintain, and improve their daily habits
- Analyse their streaks and completion data to give tailored advice
- Keep them accountable without being harsh
- Celebrate wins, diagnose slip-ups, and suggest concrete next steps

When the user shares their habit data, reference it directly.\
"""

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(title="Jarvis Habit Coach", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Pydantic models ───────────────────────────────────────────────────────────
class Message(BaseModel):
    role: str       # "user" | "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]
    habit_context: str = ""   # optional habit summary from the Flutter app


class TTSRequest(BaseModel):
    text: str
    voice: str = JARVIS_VOICE


# ── Helpers ───────────────────────────────────────────────────────────────────
def _build_system(habit_context: str) -> str:
    if not habit_context:
        return SYSTEM_PROMPT
    return f"{SYSTEM_PROMPT}\n\nUser's current habits:\n{habit_context}"


async def _ollama_stream(messages: list[Message], system: str):
    """
    Calls the Ollama /api/chat endpoint with stream=True and yields text chunks.
    Ollama streams newline-delimited JSON objects, each with a "message.content" field.
    """
    payload = {
        "model": OLLAMA_MODEL,
        "stream": True,
        "messages": [
            {"role": "system", "content": system},
            *[{"role": m.role, "content": m.content} for m in messages],
        ],
        "options": {
            "num_predict": 512,   # max tokens per reply
            "temperature": 0.7,
        },
    }

    async with httpx.AsyncClient(timeout=120) as client:
        async with client.stream(
            "POST",
            f"{OLLAMA_BASE_URL}/api/chat",
            json=payload,
        ) as resp:
            if resp.status_code != 200:
                body = await resp.aread()
                raise HTTPException(
                    status_code=502,
                    detail=f"Ollama error {resp.status_code}: {body.decode()}",
                )
            async for line in resp.aiter_lines():
                if not line.strip():
                    continue
                try:
                    data = json.loads(line)
                    chunk = data.get("message", {}).get("content", "")
                    if chunk:
                        yield chunk
                    if data.get("done"):
                        break
                except json.JSONDecodeError:
                    continue


# ── Routes ────────────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    """Check if Ollama is reachable and which model is loaded."""
    try:
        async with httpx.AsyncClient(timeout=4) as client:
            r = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
            models = [m["name"] for m in r.json().get("models", [])]
        ollama_ok = True
    except Exception:
        models = []
        ollama_ok = False

    return {
        "status": "ok" if ollama_ok else "ollama_offline",
        "ollama": ollama_ok,
        "model": OLLAMA_MODEL,
        "available_models": models,
        "tts": TTS_AVAILABLE,
        "stt": STT_AVAILABLE,
    }


@app.post("/chat")
async def chat(req: ChatRequest):
    """Streaming SSE chat — Flutter reads `data:` lines and appends to the bubble."""
    system = _build_system(req.habit_context)

    async def event_stream():
        try:
            async for chunk in _ollama_stream(req.messages, system):
                payload = json.dumps({"text": chunk})
                yield f"data: {payload}\n\n"
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
    """Convert text to speech (edge-tts — free, no API key). Returns MP3 bytes."""
    if not TTS_AVAILABLE:
        raise HTTPException(
            status_code=501,
            detail="edge-tts not installed. Run: pip install edge-tts",
        )

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
        raise HTTPException(
            status_code=501,
            detail="openai-whisper not installed. Run: pip install openai-whisper",
        )

    global _whisper_model
    if _whisper_model is None:
        _whisper_model = _whisper_lib.load_model("base")   # ~150 MB, CPU-friendly

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
