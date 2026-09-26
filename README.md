# 🏥 Hilfe zur Pflege — KI-Chatbot & Antragssystem

> **Landkreis Hildesheim** · IT-Projekt · Flutter · Python · FastAPI · Typebot · Mistral AI

A fully self-hosted, AI-powered care assistance application for the *Hilfe zur Pflege* (care assistance) department of Landkreis Hildesheim. Citizens can ask questions about care services in natural language and automatically fill out the official application form — available via native Flutter desktop/mobile apps and web interface, all without internet-dependent AI services.

---

## ✨ Features

- 📱 **Native Flutter Chat UI** — Cross-platform chat interface for macOS, iOS, Android, Web & Windows with native message bubbles
- 🤖 **AI Chatbot** — Answers questions about care assistance (Pflegehilfe) using local LLM (Mistral 7B via Ollama)
- 📄 **RAG System** — Retrieval-Augmented Generation using ChromaDB and real care documents
- 🧠 **Conversation Memory** — Remembers user name and context within a session
- 🚨 **Crisis Detection** — Detects suicide/self-harm keywords and responds with emergency contacts immediately
- 🛡️ **Topic Guardrails** — Strictly limited to care-related topics only
- 📝 **Application Form** — Guides users through the official care application step by step
- 📥 **PDF Generation & Interactive Download** — Automatically fills the official PDF form and provides a direct, clickable download button
- 🔊 **Text-to-Speech (TTS)** — Speaks chatbot answers aloud in multiple languages
- 🌍 **Multilingual** — Supports German 🇩🇪, English 🇬🇧, French 🇫🇷, Arabic 🇸🇦 (with RTL support)
- 🔒 **Admin Dashboard & Auth** — HTTP Basic Auth protected dashboard to view submitted applications and download PDFs

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Flutter Native App (Client)                 │
│      (Native UI Chat Interface, TTS, Local Translation)     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Typebot REST API (startChat / continueChat)
            ┌──────────▼───────────┐
            │    Typebot Viewer    │  Port 8081 (Docker)
            │   (Workflow Engine)  │
            └──────────┬───────────┘
                       │ HTTP Webhook (POST /ask or /submit_application)
                       │ via ngrok HTTPS tunnel
            ┌──────────▼───────────┐
            │   FastAPI Backend    │  Port 8000 (Python)
            │       main.py        │
            └──┬──────────┬────────┘
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
| **Chat Interface** | [Flutter](https://flutter.dev) + Dart | Native cross-platform Chat UI (macOS, iOS, Android, Web) |
| **Workflow Engine** | [Typebot](https://typebot.io) (Docker) | Conversational flow state machine & REST API |
| **Backend API** | [FastAPI](https://fastapi.tiangolo.com) + Uvicorn | REST API, AI RAG logic, PDF generation & Admin Auth |
| **LLM** | [Ollama](https://ollama.com) + Mistral 7B | Local AI — no internet required |
| **Vector DB** | [ChromaDB](https://www.trychroma.com) | Semantic search over care documents |
| **App Database** | SQLite | Stores submitted application forms |
| **PDF Processing** | [PyMuPDF (fitz)](https://pymupdf.readthedocs.io) | Reads and fills PDF forms |
| **Tunnel** | [ngrok](https://ngrok.com) | Exposes local server via HTTPS |
| **Containerization** | Docker Compose | Runs Typebot + PostgreSQL + Redis |

---

## 📁 Project Structure

```
.
├── flutter_app/                     # 📱 Flutter cross-platform source code (Chat UI)
│   ├── lib/                         # Dart source code (screens, widgets, providers)
│   ├── macos/                       # macOS desktop build project
│   ├── android/                     # Android build project
│   ├── ios/                         # iOS build project
│   ├── web/                         # Web build project
│   ├── pubspec.yaml                 # Flutter dependencies & metadata
│   └── ...
├── main.py                          # 🐍 FastAPI app — all endpoints, RAG and AI logic
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
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (for running the client app)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Ollama](https://ollama.com/download) installed and running
- [ngrok](https://ngrok.com/download) account + static domain
- Python 3.11+

---

### Step 1 — Clone the repository

```bash
git clone https://github.com/benyousseflamiae93-lang/hilfe-zur-pflege-chatbot.git
cd hilfe-zur-pflege-chatbot
```

### Step 2 — Set up Python environment & Backend

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Step 3 — Configure environment

```bash
cp .env.example .env
# Edit .env and fill in your ngrok URL and admin credentials
```

### Step 4 — Pull the AI model

```bash
ollama pull mistral
```

### Step 5 — Load knowledge documents into ChromaDB

```bash
python3 ingest_pdf.py
```

### Step 6 — Start Typebot (Docker)

```bash
docker compose -p itprojekt up -d
```

- Typebot Builder: http://localhost:8080
- Typebot Viewer: http://localhost:8081

### Step 7 — Start FastAPI + ngrok

```bash
./restart.sh
```

- FastAPI API: http://localhost:8000
- Protected Admin Dashboard: http://localhost:8000/admin (Default login: `admin` / `admin`)

---

### Step 8 — Run the Flutter App

```bash
cd flutter_app
flutter pub get
flutter run -d macos    # or android, ios, chrome
```

---

## 📡 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/ask` | Answer a care-related question using RAG + Mistral |
| `POST` | `/submit_application` | Submit application form data and generate PDF |
| `GET` | `/download_pdf/{session_id}` | Download the generated PDF by session |
| `POST` | `/reset_chat` | Clear conversation history for a session |
| `GET` | `/admin` | Protected Admin dashboard (HTTP Basic Auth) |
| `GET` | `/` | API root / health check |

---

## 🔒 Privacy & Security

- ✅ **No external AI API** — Mistral runs 100% locally via Ollama
- ✅ **No cloud storage** — All data stays on your machine
- ✅ **No personal data in repository** — `.gitignore` excludes all databases and generated PDFs
- ✅ **Admin Authentication** — The admin dashboard (`/admin`) is secured with HTTP Basic Auth (`ADMIN_USERNAME` / `ADMIN_PASSWORD`)
- ⚠️ Never commit your `.env` file — use `.env.example` as a template

---

## 📜 License

This project was developed as a university IT project for the Landkreis Hildesheim care assistance department.

---

## 👩‍💻 Author

**Lamiae Benyoussef**  
IT-Projekt — Hilfe zur Pflege  
Landkreis Hildesheim · 2026
