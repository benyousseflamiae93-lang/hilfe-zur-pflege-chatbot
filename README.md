# 🏥 Hilfe zur Pflege — KI-Chatbot & Antragssystem

> **Landkreis Hildesheim** · IT-Projekt · Python · FastAPI · Typebot · Mistral AI

A fully self-hosted, AI-powered care assistance chatbot for the *Hilfe zur Pflege* (care assistance) department of Landkreis Hildesheim. Citizens can ask questions about care services in natural language and automatically fill out the official application form — all without internet-dependent AI services.

---

## ✨ Features

- 🤖 **AI Chatbot** — Answers questions about care assistance (Pflegehilfe) using local LLM (Mistral 7B via Ollama)
- 📄 **RAG System** — Retrieval-Augmented Generation using ChromaDB and real care documents
- 🧠 **Conversation Memory** — Remembers user name and context within a session
- 🚨 **Crisis Detection** — Detects suicide/self-harm keywords and responds with emergency contacts immediately
- 🛡️ **Topic Guardrails** — Strictly limited to care-related topics only
- 📝 **Application Form** — Guides users through the official care application step by step
- 📥 **PDF Generation** — Automatically fills the official PDF form and provides a download link
- 🌍 **Multilingual** — Supports German 🇩🇪, English 🇬🇧, French 🇫🇷, Arabic 🇸🇦
- 🖥️ **Admin Dashboard** — View all submitted applications and download generated PDFs

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User (Browser)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
           ┌───────────▼───────────┐
           │    Typebot Viewer     │  Port 8081 (Docker)
           │   (Chat Interface)    │
           └───────────┬───────────┘
                       │ HTTP Webhook (POST /ask or /submit_application)
                       │ via ngrok HTTPS tunnel
           ┌───────────▼───────────┐
           │   FastAPI Backend     │  Port 8000 (Python)
           │      main.py         │
           └──┬──────────┬─────────┘
              │          │
   ┌──────────▼──┐  ┌────▼──────────┐
   │  ChromaDB   │  │  Ollama       │
   │  (RAG Docs) │  │  Mistral 7B   │
   └─────────────┘  └───────────────┘
              │
   ┌──────────▼──────────┐
   │  SQLite Database    │  (submitted applications)
   │  PyMuPDF PDF Fill   │  (generated_pdfs/)
   └─────────────────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend** | [Typebot](https://typebot.io) (Docker) | Chat interface for users |
| **Backend API** | [FastAPI](https://fastapi.tiangolo.com) + Uvicorn | REST API, logic, PDF generation |
| **LLM** | [Ollama](https://ollama.com) + Mistral 7B | Local AI — no internet required |
| **Vector DB** | [ChromaDB](https://www.trychroma.com) | Semantic search over care documents |
| **App Database** | SQLite | Stores submitted application forms |
| **PDF Processing** | [PyMuPDF (fitz)](https://pymupdf.readthedocs.io) | Reads and fills PDF forms |
| **Tunnel** | [ngrok](https://ngrok.com) | Exposes local server via HTTPS |
| **Containerization** | Docker Compose | Runs Typebot + PostgreSQL + Redis |

---

## 📁 Project Structure

```
IT/
├── main.py                          # FastAPI app — all endpoints and AI logic
├── ingest_pdf.py                    # Script to load PDF documents into ChromaDB
├── restart.sh                       # Start FastAPI + ngrok in background
├── requirements.txt                 # Python dependencies
├── .env.example                     # Environment variable template
├── Antrag_-_mit_Anlagen_G_DS_WG_B.PDF  # Official application form template
└── PDF/                             # Source documents for RAG knowledge base
    ├── BMG_Ratgeber_Pflege.pdf
    ├── SGB_XII_Hilfe_zur_Pflege.pdf
    ├── Merkblatt_HzP.pdf
    └── ...
```

**Auto-generated (not in repository):**
```
├── .venv/              # Python virtual environment
├── chroma_db/          # ChromaDB vector database
├── generated_pdfs/     # Filled application PDFs
├── applications.db     # SQLite database
└── ngrok               # ngrok binary
```

---

## 🚀 Installation & Setup

### Prerequisites

- macOS / Linux
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Ollama](https://ollama.com/download) installed and running
- [ngrok](https://ngrok.com/download) account + static domain
- Python 3.11+

---

### Step 1 — Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/hilfe-zur-pflege-chatbot.git
cd hilfe-zur-pflege-chatbot/IT
```

### Step 2 — Set up Python environment

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Step 3 — Configure environment

```bash
cp .env.example .env
# Edit .env and fill in your ngrok URL and other settings
```

### Step 4 — Pull the AI model

```bash
ollama pull mistral
```

### Step 5 — Load knowledge documents into ChromaDB

```bash
python3 ingest_pdf.py
```

> Place your PDF documents in the `PDF/` folder before running this.

### Step 6 — Start Typebot (Docker)

```bash
cd ..   # go to the typebot/ folder (one level up)
docker compose -p itprojekt up -d
```

- Typebot Builder: http://localhost:8080
- Typebot Viewer: http://localhost:8081

### Step 7 — Start FastAPI + ngrok

```bash
cd IT
./restart.sh
```

- FastAPI API: http://localhost:8000
- Admin Dashboard: http://localhost:8000/admin

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/ask` | Answer a care-related question using RAG + Mistral |
| `POST` | `/submit_application` | Submit application form data and generate PDF |
| `GET` | `/download_pdf/{session_id}` | Download the generated PDF by session |
| `POST` | `/reset_chat` | Clear conversation history for a session |
| `GET` | `/admin` | Admin dashboard (view all applications) |
| `GET` | `/` | API root / health check |

### Example `/ask` request

```json
POST /ask
{
  "question": "Welche Dokumente brauche ich für Pflegegrad 3?",
  "session_id": "user-abc-123",
  "language": "de"
}
```

```json
Response:
{
  "answer": "Für Pflegegrad 3 benötigen Sie folgende Unterlagen...",
  "sources": ["SGB_XII_Hilfe_zur_Pflege.pdf"]
}
```

---

## 🧠 How RAG Works

1. PDF documents in `PDF/` are split into text chunks
2. Each chunk is converted to a vector embedding and stored in **ChromaDB**
3. When a user asks a question, it is also vectorized
4. The **3 most semantically similar** document chunks are retrieved
5. These chunks are passed as context to **Mistral 7B** alongside the question
6. Mistral generates a grounded, accurate answer based only on the documents

---

## 🛡️ Safety Features

### Topic Guardrail
The bot **only answers questions about care assistance** (Hilfe zur Pflege). General questions are politely refused.

### Crisis Detection
If a message contains suicide or self-harm keywords in any supported language, the bot immediately responds with:
- German emergency number: **0800 111 0 111** (free, 24/7)
- Emergency services: **112**

No AI model is called — the crisis response is instant and hardcoded.

---

## 🌍 Multilingual Support

The system supports 4 languages. Questions are translated to German for ChromaDB search, then answers are translated back:

| Language | Code |
|---|---|
| German 🇩🇪 | `de` (default) |
| English 🇬🇧 | `en` |
| French 🇫🇷 | `fr` |
| Arabic 🇸🇦 | `ar` |

---

## ⚙️ Logs & Debugging

```bash
# FastAPI live logs
tail -f /path/to/IT/uvicorn.log

# ngrok live logs
tail -f /path/to/IT/ngrok.log

# Check running processes
ps aux | grep -E 'uvicorn|ngrok'

# Docker logs (Typebot)
docker logs itprojekt-typebot-viewer-1 --tail 30
```

---

## 📋 Requirements

```
fastapi
uvicorn
chromadb
ollama
pymupdf
```

Install all with:
```bash
pip install -r requirements.txt
```

---

## 🔒 Privacy & Security

- ✅ **No external AI API** — Mistral runs 100% locally via Ollama
- ✅ **No cloud storage** — All data stays on your machine
- ✅ **No personal data in repository** — `.gitignore` excludes all databases and PDFs
- ⚠️ The admin dashboard (`/admin`) has **no authentication** — use only on a trusted local network
- ⚠️ Never commit your `.env` file — use `.env.example` as a template

---

## 📜 License

This project was developed as a university IT project for the Landkreis Hildesheim care assistance department.

---

## 👩‍💻 Author

**Lamiae Ben Youssef**  
IT-Projekt — Hilfe zur Pflege  
Landkreis Hildesheim · 2026
