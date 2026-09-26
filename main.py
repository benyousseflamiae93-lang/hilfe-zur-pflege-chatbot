import chromadb
import ollama
import sys
import os
import uuid
import sqlite3
import fitz  # PyMuPDF
import secrets
from fastapi import FastAPI, HTTPException, Request, Depends, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, HTMLResponse
from pydantic import BaseModel
from typing import Optional

# Ensure UTF-8 output for console
sys.stdout.reconfigure(encoding='utf-8')

app = FastAPI()


# ADMIN AUTHENTICATION
# ============================================================

security = HTTPBasic()

ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin")

def require_admin(
    credentials: HTTPBasicCredentials = Depends(security)
):
    if not ADMIN_PASSWORD:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Admin authentication is not configured."
        )

    username_ok = secrets.compare_digest(
        credentials.username,
        ADMIN_USERNAME
    )

    password_ok = secrets.compare_digest(
        credentials.password,
        ADMIN_PASSWORD
    )

    if not (username_ok and password_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid admin credentials",
            headers={"WWW-Authenticate": "Basic"},
        )

    return credentials.username

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------------------------------------------------------------
#Database & Directories Setup
# ----------------------------------------------------------------------
DB_PATH = "applications.db"
PDF_DIR = "generated_pdfs"
os.makedirs(PDF_DIR, exist_ok=True)

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS applications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT UNIQUE,
            nachname TEXT,
            vorname TEXT,
            geburtsname TEXT,
            email_adresse TEXT,
            id_nummer TEXT,
            staatsangehoerigkeit TEXT,
            aufenthaltsstatus TEXT,
            schwerbehinderung TEXT,
            grad TEXT,
            pflegeversicherung TEXT,
            art_versicherung TEXT,
            pflege_grade TEXT,
            hilfe_art TEXT,
            vorher_sozialhilfe TEXT,
            zimmer_typ TEXT,
            aufnahme_datum TEXT,
            einrichtung_name TEXT,
            einrichtung_strasse TEXT,
            einrichtung_ort TEXT,
            partner_name TEXT,
            partner_vorname TEXT,
            geburtsname_partner TEXT,
            geburtsdatum_ort_partner TEXT,
            email_adresse_partner TEXT,
            staatsangehoerigkeit_partner TEXT,
            aufenthaltsstatus_partner TEXT,
            grad_partner TEXT,
            pflegeversicherung_partner TEXT,
            art_versicherung_partner TEXT,
            pflegegrade_partner TEXT,
            partner_angabe TEXT,
            name_betreuung TEXT,
            adresse_betreuung TEXT,
            plz_wohnort_betreuung TEXT,
            email_adresse_betreuung TEXT,
            adresse_wohnverhaeltniss TEXT,
            up1_name TEXT,
            up1_vorname TEXT,
            up1_geburtsdatum TEXT,
            up1_geburtsort TEXT,
            up1_staatsangehoerigkeit TEXT,
            up1_familienstand TEXT,
            up1_verwandtschaft TEXT,
            up1_wohnort_plz TEXT,
            up1_strasse TEXT,
            up1_beruf TEXT,
            up1_art_einkommen TEXT,
            up1_brutto_ueber_100k TEXT,
            up2_name TEXT,
            up2_vorname TEXT,
            up2_geburtsdatum TEXT,
            up2_geburtsort TEXT,
            up2_staatsangehoerigkeit TEXT,
            up2_familienstand TEXT,
            up2_verwandtschaft TEXT,
            up2_wohnort_plz TEXT,
            up2_strasse TEXT,
            up2_beruf TEXT,
            up2_art_einkommen TEXT,
            up2_brutto_ueber_100k TEXT,
            up_anzahl_personen TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            pdf_path TEXT
        )
    """)
    conn.commit()
    conn.close()

init_db()

def migrate_db():
    """Add new columns to existing DB without breaking old data."""
    new_columns = [
        ("up1_name", "TEXT"), ("up1_vorname", "TEXT"), ("up1_geburtsdatum", "TEXT"),
        ("up1_geburtsort", "TEXT"), ("up1_staatsangehoerigkeit", "TEXT"),
        ("up1_familienstand", "TEXT"), ("up1_verwandtschaft", "TEXT"),
        ("up1_wohnort_plz", "TEXT"), ("up1_strasse", "TEXT"), ("up1_beruf", "TEXT"),
        ("up1_art_einkommen", "TEXT"), ("up1_brutto_ueber_100k", "TEXT"),
        ("up2_name", "TEXT"), ("up2_vorname", "TEXT"), ("up2_geburtsdatum", "TEXT"),
        ("up2_geburtsort", "TEXT"), ("up2_staatsangehoerigkeit", "TEXT"),
        ("up2_familienstand", "TEXT"), ("up2_verwandtschaft", "TEXT"),
        ("up2_wohnort_plz", "TEXT"), ("up2_strasse", "TEXT"), ("up2_beruf", "TEXT"),
        ("up2_art_einkommen", "TEXT"), ("up2_brutto_ueber_100k", "TEXT"),
        ("up_anzahl_personen", "TEXT"),
    ]
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    existing = [row[1] for row in c.execute("PRAGMA table_info(applications)")]
    for col_name, col_type in new_columns:
        if col_name not in existing:
            c.execute(f"ALTER TABLE applications ADD COLUMN {col_name} {col_type}")
    conn.commit()
    conn.close()

migrate_db()

# ----------------------------------------------------------------------
#ChromaDB / RAG Setup
# ----------------------------------------------------------------------
client = chromadb.PersistentClient(path="./chroma_db")
collection = client.get_or_create_collection(name="pflege_docs")

# Conversation Memory Stores
chat_histories = {}       # session_id -> list of dialogue turns
session_user_names = {}   # session_id -> extracted user name (e.g. "Lamiae")

class AskBody(BaseModel):
    question: str
    session_id: Optional[str] = None
    language: Optional[str] = "de"

class ResetBody(BaseModel):
    session_id: str

@app.post("/reset_chat")
def reset_chat(body: ResetBody):
    sid = body.session_id
    if sid:
        if sid in chat_histories:
            del chat_histories[sid]
        if sid in session_user_names:
            del session_user_names[sid]
        print(f"MEMORIES CLEARED FOR SESSION: {sid}", flush=True)
    return {"status": "cleared", "session_id": sid}

@app.get("/reset_chat/{session_id}")
def reset_chat_get(session_id: str):
    if session_id:
        if session_id in chat_histories:
            del chat_histories[session_id]
        if session_id in session_user_names:
            del session_user_names[session_id]
        print(f"MEMORIES CLEARED FOR SESSION: {session_id}", flush=True)
    return {"status": "cleared", "session_id": session_id}

# ==============================================================
# Crisis / Suicide Detection
# ==============================================================
CRISIS_KEYWORDS = [
    "mich umbringen",
    "umbringen",
    "suizid",
    "selbstmord",
    "mir das leben nehmen",
    "leben nehmen",
    "nicht mehr leben",
    "nicht mehr leben wollen",
    "will nicht mehr leben",
    "ich will nicht mehr leben",
    "ich will sterben",
    "keine lust mehr zu leben",
    "mich töten",
    "ich will mich töten",
    "selbstverletzung",
    "selbst verletzen",
    "mich selbst verletzen",
    "ritzen",
    # English
    "i want to die",
    "i want to kill myself",
    "i want to end my life",
    "kill myself",
    "end my life",
    "suicide",
    "self harm",
    "self-harm",
    "hurt myself",
    "don't want to live",
    "don't want to be alive",
    # French
    "je veux mourir",
    "me suicider",
    "mettre fin à ma vie",
    # Arabic
    "أريد الموت",
    "أريد قتل نفسي",
    "الانتحار",
]

CRISIS_RESPONSE_DE = (
    "Es klingt so, als könnten Sie sich gerade in einer sehr belastenden Situation befinden. "
    "Bitte bleiben Sie damit nicht allein. Wenden Sie sich jetzt an eine vertraute Person "
    "oder rufen Sie die Telefonseelsorge an – kostenlos und rund um die Uhr:\n\n"
    "📞 0800 111 0 111 (kostenlos, 24/7)\n"
    "📞 0800 111 0 222 (kostenlos, 24/7)\n\n"
    "Bei unmittelbarer Gefahr: Notruf 112 wählen."
)
CRISIS_RESPONSE_EN = (
    "It sounds like you may be going through a very difficult time. "
    "Please don't face this alone. Reach out to someone you trust or contact a crisis line:\n\n"
    "📞 International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/\n\n"
    "If you are in immediate danger, please call emergency services: 112."
)
CRISIS_RESPONSE_FR = (
    "Il semble que vous traversez une période très difficile. "
    "Vous n'êtes pas seul(e). Contactez une personne de confiance ou appelez le:\n\n"
    "📞 3114 – Numéro national de prévention du suicide (gratuit, 24h/24)\n\n"
    "En cas de danger immédiat: composez le 112."
)
CRISIS_RESPONSE_AR = (
    "يبدو أنك تمر بوقت صعب للغاية. من فضلك لا تواجه هذا وحدك. "
    "تواصل مع شخص تثق به أو اتصل بخط مساعدة الأزمات.\n\n"
    "📞 في حالة الخطر الفوري: اتصل بالطوارئ 112."
)

CRISIS_RESPONSES = {
    "de": CRISIS_RESPONSE_DE,
    "en": CRISIS_RESPONSE_EN,
    "fr": CRISIS_RESPONSE_FR,
    "ar": CRISIS_RESPONSE_AR,
}

def is_crisis(text: str) -> bool:
    """Returns True if the message contains suicide/self-harm keywords."""
    q = text.lower().strip()
    return any(keyword in q for keyword in CRISIS_KEYWORDS)

def extract_user_name(text: str) -> Optional[str]:
    import re
    if not text:
        return None
    # Normalize punctuation attached to name by replacing commas/dots/punctuation with spaces
    clean_input = re.sub(r'[,.!?;\:\(\)]', ' ', text)
    patterns = [
        r'(?:mein|meine|meinen)?\s*name\s+ist\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)',
        r'ich\s+hei[ßs]e\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)',
        r'ich\s+bin\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)',
        r'my\s+name\s+is\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)',
        r'i\s+am\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)',
        r'je\s+m\'appelle\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)',
        r'اسمي\s+([A-Za-zäöüßÄÖÜ\u0600-\u06FF]+)'
    ]
    for p in patterns:
        m = re.search(p, clean_input, re.IGNORECASE)
        if m:
            name = m.group(1).strip().capitalize()
            stop_words = {
                "ein", "eine", "einen", "der", "die", "das", "dem", "den", "des",
                "the", "a", "an", "le", "la", "les", "un", "une", "und", "and", "et",
                "hier", "da", "sehr", "gut", "alt", "neu", "krank", "pflege", "kannst", "kann"
            }
            if name.lower() not in stop_words and len(name) >= 2:
                return name
    return None

def is_name_recall_query(question: str) -> bool:
    q = question.lower().strip()
    patterns = [
        "wie heiße ich", "wie heisse ich", "wie ist mein name", "was ist mein name",
        "weißt du wie ich heiße", "weisst du wie ich heisse", "kennst du meinen namen",
        "weißt du meinen namen", "weisst du meinen namen", "what is my name", "what's my name",
        "do you know my name", "remind me of my name", "remind me my name", "quel est mon nom",
        "comment je m'appelle", "ما هو اسمي", "هل تعرف اسمي"
    ]
    return any(p in q for p in patterns)

def clean_pdf_text(text: str) -> str:
    import re
    if not text:
        return ""
    # Add space between squished camel-case/heading words (e.g. VornameGeburtsdatum -> Vorname Geburtsdatum)
    cleaned = re.sub(r'([a-zäöüß])([A-ZÄÖÜ])', r'\1 \2', text)
    # Add space between closing parenthesis and next word
    cleaned = re.sub(r'([\)])([A-ZÄÖÜa-zäöüß])', r'\1 \2', cleaned)
    # Add space after colons/commas if missing
    cleaned = re.sub(r'([,;:!?])([A-ZÄÖÜa-zäöüß])', r'\1 \2', cleaned)
    # Normalize extra spaces
    cleaned = re.sub(r'[ \t]+', ' ', cleaned)
    return cleaned.strip()

def translate_locally(text: str, from_lang: str, to_lang: str) -> str:
    """Translate text between languages using local Ollama (Llama3/Mistral)."""
    if from_lang == to_lang or not text.strip():
        return text
    lang_names = {"de": "German", "en": "English", "fr": "French", "ar": "Arabic"}
    src = lang_names.get(from_lang, from_lang)
    tgt = lang_names.get(to_lang, to_lang)
    prompt = f"Translate the following text from {src} to {tgt}. Return ONLY the exact translated text without any commentary or quotation marks:\n\n{text}"
    try:
        res = ollama.chat(model="mistral", messages=[{"role": "user", "content": prompt}])
        translated = res["message"]["content"].strip()
        return translated if translated else text
    except Exception as e:
        print(f"LOCAL TRANSLATION ERROR: {e}", flush=True)
        return text

def is_allowed_topic(question: str) -> bool:
    """
    Returns True if the question is related to Care/Pflege, greetings, name introductions, 
    or conversation history/name memory recall queries (e.g., 'Wie heiße ich?'). 
    Returns False for general trivia/geography/weather/etc. (e.g., 'Wo liegt Berlin?').
    """
    q = question.lower().strip()
    
    # 1. Memory / Name Recall & Introductions & Greetings
    memory_and_intro_keywords = [
        "wie heiße ich", "wie heisse ich", "wie ist mein name", "was ist mein name",
        "weißt du wie ich heiße", "weisst du wie ich heisse", "kennst du meinen namen",
        "weißt du meinen namen", "weisst du meinen namen", "errinere mich", "erinnere mich",
        "mein name", "meinen namen", "what is my name", "what's my name", "do you know my name",
        "remind me of my name", "remind me my name", "remind me", "quel est mon nom",
        "comment je m'appelle", "ما هو اسمي", "هل تعرف اسمي", "تذكر اسمي",
        "hallo", "hello", "hey", "hi", "guten tag", "guten morgen", "guten abend", 
        "bonjour", "salut", "مرحبا", "أهلا", "سلام", "ich bin", "mein name ist", 
        "my name is", "i am", "je m'appelle", "اسمي", "danke", "thank you", "merci", "شكرا"
    ]
    if any(k in q for k in memory_and_intro_keywords):
        return True
        
    # Single-word polite greetings
    if q in ["hallo", "hello", "hey", "hi", "bonjour", "salut", "مرحبا", "danke", "merci"]:
        return True


    # 2. Care & Administrative Keywords
    care_keywords = [
        "pflege", "pflegegrad", "hilfe zur pflege", "antrag", "pflegekasse", 
        "versicherung", "medizinisch", "care", "sozialhilfe", "nachrang", 
        "einkommen", "vermögen", "eigenanteil", "kosten", "heimkosten", 
        "zuzahlung", "unterhalt", "sgb", "dokument", "dokumente", "unterlagen", 
        "nachweis", "formular", "ausfüllen", "apply", "document", "documents", 
        "hilfebedürftig", "einrichtung", "betreuung", "hildesheim", "landkreis",
        "vorsorgevollmacht", "patientenverfügung", "heim", "pflegedienst"
    ]
    if any(k in q for k in care_keywords):
        return True
        
    return False

def ask_rag(question: str, session_id: Optional[str] = None, language: str = "de", user_display_text: Optional[str] = None):
    # Vector search against ChromaDB PDF store
    results = collection.query(query_texts=[question], n_results=3)
    docs = results["documents"][0] if results and "documents" in results and results["documents"] else []
    raw_context = "\n\n".join(d.strip() for d in docs if d.strip()) if docs else ""
    context = clean_pdf_text(raw_context)

    lang_names = {
        "de": "German",
        "en": "English",
        "fr": "French",
        "ar": "Arabic"
    }
    target_lang = lang_names.get(language.lower(), "German")
    
    # Retrieve active user name for session if known
    user_name = session_user_names.get(session_id) if session_id else None
    name_instruction = f" The user's name is {user_name}. Always address the user politely by name (e.g., 'Hallo {user_name}')." if user_name else ""

    system_prompt = (
        f"You are a specialized AI assistant EXCLUSIVELY for 'Hilfe zur Pflege' (Care Assistance under SGB XII, Landkreis Hildesheim, Germany).\n\n"
        f"STRICT RULES:\n"
        f"1. You MUST answer EXCLUSIVELY in {target_lang}.{name_instruction}\n"
        f"2. Answer questions about care (Pflege), care grades (Pflegegrade), care applications (Antrag), required documents, social assistance, and care insurance accurately and clearly.\n"
        f"3. Do NOT answer general trivia, geography (e.g. 'Wo liegt Berlin?'), weather, or unrelated topics.\n"
        f"4. Keep responses helpful, friendly, accurately formatted with clear word spacing, and concise."
    )

    messages = [{"role": "system", "content": system_prompt}]

    # Include complete conversation history for this session
    if session_id and session_id in chat_histories:
        for msg in chat_histories[session_id]:
            messages.append({"role": msg["role"], "content": msg["content"]})

    display_q = user_display_text if user_display_text else question
    user_payload = f"Relevant Care Documents:\n{context}\n\nUser Question: {display_q}" if context else f"User Question: {display_q}"
    messages.append({"role": "user", "content": user_payload})

    # Call local Ollama chat model with complete message history
    response = ollama.chat(
        model="mistral",
        messages=messages,
        options={"num_predict": 350, "temperature": 0.2}
    )
    answer = clean_pdf_text(response["message"]["content"].strip())

    # Save to conversation memory (store the user's original display text for readability)
    if session_id:
        if session_id not in chat_histories:
            chat_histories[session_id] = []
        chat_histories[session_id].append({"role": "user", "content": display_q})
        chat_histories[session_id].append({"role": "assistant", "content": answer})

    return answer, docs

# ----------------------------------------------------------------------
# PDF Filler Coordinates Logic
# ----------------------------------------------------------------------
def fill_pdf(data: dict, output_path: str):
    base_pdf = "./Antrag_-_mit_Anlagen_G_DS_WG_B.PDF"
    if not os.path.exists(base_pdf):
        base_pdf = "/Users/benyousseflamiae/Desktop/typebot/IT/Antrag_-_mit_Anlagen_G_DS_WG_B.PDF"
    if not os.path.exists(base_pdf):
        raise FileNotFoundError(f"Base PDF not found at {base_pdf}")
        
    doc = fitz.open(base_pdf)
    
    # Page 1
    page1 = doc[0]
    
    # Art der Hilfe zur Pflege
    hilfe_art = str(data.get("hilfe_art", "")).strip().lower()
    if "vollstation" in hilfe_art:
        page1.insert_text(fitz.Point(65.0, 417.0), "X", fontsize=12)
    elif "teilstation" in hilfe_art:
        page1.insert_text(fitz.Point(320.0, 427.0), "X", fontsize=12)
    elif "huslich" in hilfe_art or "häuslich" in hilfe_art or "hauslich" in hilfe_art:
        page1.insert_text(fitz.Point(55.0, 448.0), "X", fontsize=12)
        
    # Sozialhilfe vor Aufnahme?
    vorher_soz = str(data.get("vorher_sozialhilfe", "")).strip().lower()
    if vorher_soz == "ja":
        page1.insert_text(fitz.Point(418.0, 588.0), "X", fontsize=12)
    elif vorher_soz == "nein":
        page1.insert_text(fitz.Point(445.0, 588.0), "X", fontsize=12)
        
    # Einrichtung details
    if data.get("einrichtung_name"):
        page1.insert_text(fitz.Point(250.0, 608.0), str(data.get("einrichtung_name")), fontsize=10)
    if data.get("einrichtung_strasse"):
        page1.insert_text(fitz.Point(250.0, 633.0), str(data.get("einrichtung_strasse")), fontsize=10)
    if data.get("einrichtung_ort"):
        page1.insert_text(fitz.Point(250.0, 654.0), str(data.get("einrichtung_ort")), fontsize=10)
    if data.get("aufnahme_datum"):
        page1.insert_text(fitz.Point(250.0, 674.0), str(data.get("aufnahme_datum")), fontsize=10)
        
    # Zimmertyp
    zimmer = str(data.get("zimmer_typ", "")).strip().lower()
    if "einzel" in zimmer:
        page1.insert_text(fitz.Point(115.0, 693.0), "X", fontsize=12)
    elif "doppel" in zimmer:
        page1.insert_text(fitz.Point(195.0, 693.0), "X", fontsize=12)

    # Page 2
    page2 = doc[1]
    
    # Nachname
    if data.get("nachname"):
        page2.insert_text(fitz.Point(250.0, 107.0), str(data.get("nachname")), fontsize=10)
    if data.get("partner_name"):
        page2.insert_text(fitz.Point(410.0, 107.0), str(data.get("partner_name")), fontsize=10)
        
    # Vorname
    if data.get("vorname"):
        page2.insert_text(fitz.Point(250.0, 128.0), str(data.get("vorname")), fontsize=10)
    if data.get("partner_vorname"):
        page2.insert_text(fitz.Point(410.0, 128.0), str(data.get("partner_vorname")), fontsize=10)
        
    # Geburtsname
    if data.get("geburtsname"):
        page2.insert_text(fitz.Point(250.0, 148.0), str(data.get("geburtsname")), fontsize=10)
    if data.get("geburtsname_partner"):
        page2.insert_text(fitz.Point(410.0, 148.0), str(data.get("geburtsname_partner")), fontsize=10)
        
    # Geburtsdatum / -ort (partner / combined)
    if data.get("geburtsdatum_ort_partner"):
        page2.insert_text(fitz.Point(410.0, 167.0), str(data.get("geburtsdatum_ort_partner")), fontsize=10)
        
    # E-Mail-Adresse
    if data.get("email_adresse"):
        page2.insert_text(fitz.Point(250.0, 189.0), str(data.get("email_adresse")), fontsize=10)
    if data.get("email_adresse_partner"):
        page2.insert_text(fitz.Point(410.0, 189.0), str(data.get("email_adresse_partner")), fontsize=10)
        
    # Steuerliche Identifikationsnummer
    if data.get("id_nummer"):
        page2.insert_text(fitz.Point(250.0, 208.0), str(data.get("id_nummer")), fontsize=10)
        
    # Familienstand
    fam = str(data.get("familienstand", "")).strip().lower()
    if "ledig" in fam:
        page2.insert_text(fitz.Point(246.0, 222.1), "X", fontsize=12)
    elif "verheiratet" in fam:
        page2.insert_text(fitz.Point(283.0, 222.1), "X", fontsize=12)
    elif "getrennt" in fam:
        page2.insert_text(fitz.Point(246.0, 235.5), "X", fontsize=12)
    elif "geschieden" in fam:
        page2.insert_text(fitz.Point(246.0, 248.9), "X", fontsize=12)
    elif "verwitwet" in fam:
        page2.insert_text(fitz.Point(310.0, 248.9), "X", fontsize=12)
        
    # Staatsangehörigkeit
    if data.get("staatsangehoerigkeit"):
        page2.insert_text(fitz.Point(250.0, 268.0), str(data.get("staatsangehoerigkeit")), fontsize=10)
    if data.get("staatsangehoerigkeit_partner"):
        page2.insert_text(fitz.Point(410.0, 268.0), str(data.get("staatsangehoerigkeit_partner")), fontsize=10)
        
    # Aufenthaltsstatus
    if data.get("aufenthaltsstatus"):
        page2.insert_text(fitz.Point(250.0, 289.0), str(data.get("aufenthaltsstatus")), fontsize=10)
    if data.get("aufenthaltsstatus_partner"):
        page2.insert_text(fitz.Point(410.0, 289.0), str(data.get("aufenthaltsstatus_partner")), fontsize=10)
        
    # Schwerbehinderung
    schwer = str(data.get("schwerbehinderung", "")).strip().lower()
    if "ja" in schwer:
        page2.insert_text(fitz.Point(246.0, 307.0), "X", fontsize=12)
    elif "nein" in schwer:
        page2.insert_text(fitz.Point(280.0, 307.0), "X", fontsize=12)
    if data.get("grad"):
        page2.insert_text(fitz.Point(280.0, 321.0), str(data.get("grad")), fontsize=10)
        
    # Partner Schwerbehinderung
    grad_p = str(data.get("grad_partner", "")).strip().lower()
    if grad_p:
        if grad_p != "nein" and grad_p != "0":
            page2.insert_text(fitz.Point(398.0, 307.0), "X", fontsize=12)
            page2.insert_text(fitz.Point(430.0, 321.0), grad_p, fontsize=10)
        else:
            page2.insert_text(fitz.Point(432.0, 307.0), "X", fontsize=12)
            
    # Kranken- und pflegeversicherung
    if data.get("pflegeversicherung"):
        page2.insert_text(fitz.Point(250.0, 348.0), str(data.get("pflegeversicherung")), fontsize=10)
    if data.get("pflegeversicherung_partner"):
        page2.insert_text(fitz.Point(410.0, 348.0), str(data.get("pflegeversicherung_partner")), fontsize=10)
        
    # Versicherungsnummer
    # In Typebot, we map this to id_nummer or another variable. We support 'id_nummer_vers'
    if data.get("id_nummer_vers"):
        page2.insert_text(fitz.Point(250.0, 362.0), str(data.get("id_nummer_vers")), fontsize=10)
        
    # Gesetzlich/Privat
    if data.get("art_versicherung"):
        page2.insert_text(fitz.Point(250.0, 389.0), str(data.get("art_versicherung")), fontsize=10)
    if data.get("art_versicherung_partner"):
        page2.insert_text(fitz.Point(410.0, 389.0), str(data.get("art_versicherung_partner")), fontsize=10)
        
    # Pflegegrad
    if data.get("pflege_grade"):
        page2.insert_text(fitz.Point(250.0, 403.0), str(data.get("pflege_grade")), fontsize=10)
    if data.get("pflegegrade_partner"):
        page2.insert_text(fitz.Point(410.0, 403.0), str(data.get("pflegegrade_partner")), fontsize=10)
        
    # Grund der Pflegebedürftigkeit
    grund = str(data.get("grund_pflegebeduerftigkeit", "")).strip().lower()
    if "alter" in grund:
        page2.insert_text(fitz.Point(246.0, 419.9), "X", fontsize=12)
    elif "krankheit" in grund:
        page2.insert_text(fitz.Point(286.0, 419.9), "X", fontsize=12)
    elif "unfall" in grund:
        page2.insert_text(fitz.Point(345.0, 419.9), "X", fontsize=12)
    elif "fremd" in grund:
        page2.insert_text(fitz.Point(246.0, 433.3), "X", fontsize=12)
        
    # Betreuungsperson
    if data.get("name_betreuung"):
        page2.insert_text(fitz.Point(250.0, 495.0), str(data.get("name_betreuung")), fontsize=10)
    if data.get("adresse_betreuung"):
        page2.insert_text(fitz.Point(250.0, 516.0), str(data.get("adresse_betreuung")), fontsize=10)
    if data.get("plz_wohnort_betreuung"):
        page2.insert_text(fitz.Point(250.0, 536.0), str(data.get("plz_wohnort_betreuung")), fontsize=10)
    if data.get("email_adresse_betreuung"):
        page2.insert_text(fitz.Point(250.0, 557.0), str(data.get("email_adresse_betreuung")), fontsize=10)
        
    # Wohnverhältnisse
    if data.get("adresse_wohnverhaeltniss"):
        page2.insert_text(fitz.Point(250.0, 655.0), str(data.get("adresse_wohnverhaeltniss")), fontsize=10)
        
    # Wohntyp
    wohntyp = str(data.get("wohntyp", "")).strip().lower()
    if "mieter" in wohntyp:
        page2.insert_text(fitz.Point(56.0, 710.0), "X", fontsize=12)
    elif "eigent" in wohntyp or "grundst" in wohntyp:
        page2.insert_text(fitz.Point(56.0, 730.0), "X", fontsize=12)

    #Page 5 — Section 6: Unterhaltspflichtige Personen
    # Table has 4 columns; we fill col 1 (x≈175) and col 2 (x≈280)
    page5 = doc[4]
    # Column X positions for each person
    col_x = [175.0, 280.0, 365.0, 450.0]
    # Row Y positions matching the PDF labels
    rows = {
        "name":       95.0,
        "vorname":   121.0,
        "gebdat":    141.0,
        "gebort":    170.0,
        "staat":     199.0,
        "famstand":  228.0,
        "verwandt":  257.0,
        "wohnort":   286.0,
        "strasse":   314.0,
        "beruf":     372.0,
        "einkommen": 459.0,
    }

    persons = [
        {
            "name":      data.get("up1_name", ""),
            "vorname":   data.get("up1_vorname", ""),
            "gebdat":    data.get("up1_geburtsdatum", ""),
            "gebort":    data.get("up1_geburtsort", ""),
            "staat":     data.get("up1_staatsangehoerigkeit", ""),
            "famstand":  data.get("up1_familienstand", ""),
            "verwandt":  data.get("up1_verwandtschaft", ""),
            "wohnort":   data.get("up1_wohnort_plz", ""),
            "strasse":   data.get("up1_strasse", ""),
            "beruf":     data.get("up1_beruf", ""),
            "einkommen": data.get("up1_art_einkommen", ""),
            "brutto":    data.get("up1_brutto_ueber_100k", ""),
        },
        {
            "name":      data.get("up2_name", ""),
            "vorname":   data.get("up2_vorname", ""),
            "gebdat":    data.get("up2_geburtsdatum", ""),
            "gebort":    data.get("up2_geburtsort", ""),
            "staat":     data.get("up2_staatsangehoerigkeit", ""),
            "famstand":  data.get("up2_familienstand", ""),
            "verwandt":  data.get("up2_verwandtschaft", ""),
            "wohnort":   data.get("up2_wohnort_plz", ""),
            "strasse":   data.get("up2_strasse", ""),
            "beruf":     data.get("up2_beruf", ""),
            "einkommen": data.get("up2_art_einkommen", ""),
            "brutto":    data.get("up2_brutto_ueber_100k", ""),
        },
    ]

    for i, person in enumerate(persons):
        if not person.get("name") and not person.get("vorname"):
            continue  # Skip empty persons
        cx = col_x[i]
        for field, y in rows.items():
            val = person.get(field, "")
            if val:
                page5.insert_text(fitz.Point(cx, y), str(val)[:30], fontsize=8)
        # Bruttojahreseinkommen checkbox
        brutto = str(person.get("brutto", "")).strip().lower()
        if "ja" in brutto:
            page5.insert_text(fitz.Point(cx - 10, 490.0), "X", fontsize=10)
        elif "nein" in brutto:
            page5.insert_text(fitz.Point(cx + 20, 490.0), "X", fontsize=10)

    doc.save(output_path)
    doc.close()

# ----------------------------------------------------------------------
#FastAPI Request Endpoints
# ----------------------------------------------------------------------
class ApplicationFormBody(BaseModel):
    nachname: Optional[str] = ""
    vorname: Optional[str] = ""
    geburtsname: Optional[str] = ""
    email_adresse: Optional[str] = ""
    id_nummer: Optional[str] = ""
    staatsangehoerigkeit: Optional[str] = ""
    aufenthaltsstatus: Optional[str] = ""
    schwerbehinderung: Optional[str] = ""
    grad: Optional[str] = ""
    pflegeversicherung: Optional[str] = ""
    art_versicherung: Optional[str] = ""
    pflege_grade: Optional[str] = ""
    hilfe_art: Optional[str] = ""
    vorher_sozialhilfe: Optional[str] = ""
    zimmer_typ: Optional[str] = ""
    aufnahme_datum: Optional[str] = ""
    einrichtung_name: Optional[str] = ""
    einrichtung_strasse: Optional[str] = ""
    einrichtung_ort: Optional[str] = ""
    partner_name: Optional[str] = ""
    partner_vorname: Optional[str] = ""
    geburtsname_partner: Optional[str] = ""
    geburtsdatum_ort_partner: Optional[str] = ""
    email_adresse_partner: Optional[str] = ""
    staatsangehoerigkeit_partner: Optional[str] = ""
    aufenthaltsstatus_partner: Optional[str] = ""
    grad_partner: Optional[str] = ""
    pflegeversicherung_partner: Optional[str] = ""
    art_versicherung_partner: Optional[str] = ""
    pflegegrade_partner: Optional[str] = ""
    partner_angabe: Optional[str] = ""
    name_betreuung: Optional[str] = ""
    adresse_betreuung: Optional[str] = ""
    plz_wohnort_betreuung: Optional[str] = ""
    email_adresse_betreuung: Optional[str] = ""
    adresse_wohnverhaeltniss: Optional[str] = ""
    # Section 6 — Unterhaltspflichtige Personen
    up1_name: Optional[str] = ""
    up1_vorname: Optional[str] = ""
    up1_geburtsdatum: Optional[str] = ""
    up1_geburtsort: Optional[str] = ""
    up1_staatsangehoerigkeit: Optional[str] = ""
    up1_familienstand: Optional[str] = ""
    up1_verwandtschaft: Optional[str] = ""
    up1_wohnort_plz: Optional[str] = ""
    up1_strasse: Optional[str] = ""
    up1_beruf: Optional[str] = ""
    up1_art_einkommen: Optional[str] = ""
    up1_brutto_ueber_100k: Optional[str] = ""
    up2_name: Optional[str] = ""
    up2_vorname: Optional[str] = ""
    up2_geburtsdatum: Optional[str] = ""
    up2_geburtsort: Optional[str] = ""
    up2_staatsangehoerigkeit: Optional[str] = ""
    up2_familienstand: Optional[str] = ""
    up2_verwandtschaft: Optional[str] = ""
    up2_wohnort_plz: Optional[str] = ""
    up2_strasse: Optional[str] = ""
    up2_beruf: Optional[str] = ""
    up2_art_einkommen: Optional[str] = ""
    up2_brutto_ueber_100k: Optional[str] = ""
    up_anzahl_personen: Optional[str] = ""

@app.post("/submit_application")
def submit_application(body: ApplicationFormBody):
    session_id = str(uuid.uuid4())
    pdf_filename = f"filled_application_{session_id}.pdf"
    pdf_path = os.path.join(PDF_DIR, pdf_filename)
    
    # 1. Save data properly in SQLite database
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("""
            INSERT INTO applications (
                session_id, nachname, vorname, geburtsname, email_adresse, id_nummer,
                staatsangehoerigkeit, aufenthaltsstatus, schwerbehinderung, grad,
                pflegeversicherung, art_versicherung, pflege_grade, hilfe_art,
                vorher_sozialhilfe, zimmer_typ, aufnahme_datum, einrichtung_name,
                einrichtung_strasse, einrichtung_ort, partner_name, partner_vorname,
                geburtsname_partner, geburtsdatum_ort_partner, email_adresse_partner,
                staatsangehoerigkeit_partner, aufenthaltsstatus_partner, grad_partner,
                pflegeversicherung_partner, art_versicherung_partner, pflegegrade_partner,
                partner_angabe, name_betreuung, adresse_betreuung, plz_wohnort_betreuung,
                email_adresse_betreuung, adresse_wohnverhaeltniss,
                up1_name, up1_vorname, up1_geburtsdatum, up1_geburtsort,
                up1_staatsangehoerigkeit, up1_familienstand, up1_verwandtschaft,
                up1_wohnort_plz, up1_strasse, up1_beruf, up1_art_einkommen, up1_brutto_ueber_100k,
                up2_name, up2_vorname, up2_geburtsdatum, up2_geburtsort,
                up2_staatsangehoerigkeit, up2_familienstand, up2_verwandtschaft,
                up2_wohnort_plz, up2_strasse, up2_beruf, up2_art_einkommen, up2_brutto_ueber_100k,
                up_anzahl_personen, pdf_path
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            session_id, body.nachname, body.vorname, body.geburtsname, body.email_adresse, body.id_nummer,
            body.staatsangehoerigkeit, body.aufenthaltsstatus, body.schwerbehinderung, body.grad,
            body.pflegeversicherung, body.art_versicherung, body.pflege_grade, body.hilfe_art,
            body.vorher_sozialhilfe, body.zimmer_typ, body.aufnahme_datum, body.einrichtung_name,
            body.einrichtung_strasse, body.einrichtung_ort, body.partner_name, body.partner_vorname,
            body.geburtsname_partner, body.geburtsdatum_ort_partner, body.email_adresse_partner,
            body.staatsangehoerigkeit_partner, body.aufenthaltsstatus_partner, body.grad_partner,
            body.pflegeversicherung_partner, body.art_versicherung_partner, body.pflegegrade_partner,
            body.partner_angabe, body.name_betreuung, body.adresse_betreuung, body.plz_wohnort_betreuung,
            body.email_adresse_betreuung, body.adresse_wohnverhaeltniss,
            body.up1_name, body.up1_vorname, body.up1_geburtsdatum, body.up1_geburtsort,
            body.up1_staatsangehoerigkeit, body.up1_familienstand, body.up1_verwandtschaft,
            body.up1_wohnort_plz, body.up1_strasse, body.up1_beruf, body.up1_art_einkommen, body.up1_brutto_ueber_100k,
            body.up2_name, body.up2_vorname, body.up2_geburtsdatum, body.up2_geburtsort,
            body.up2_staatsangehoerigkeit, body.up2_familienstand, body.up2_verwandtschaft,
            body.up2_wohnort_plz, body.up2_strasse, body.up2_beruf, body.up2_art_einkommen, body.up2_brutto_ueber_100k,
            body.up_anzahl_personen, pdf_path
        ))
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"DATABASE ERROR: {str(e)}", flush=True)
        raise HTTPException(status_code=500, detail=f"Database save error: {str(e)}")
        
    # 2. Fill PDF document dynamically
    try:
        data_dict = body.dict()
        fill_pdf(data_dict, pdf_path)
    except Exception as e:
        print(f"PDF FILL ERROR: {str(e)}", flush=True)
        raise HTTPException(status_code=500, detail=f"PDF filling error: {str(e)}")
        
    # 3. Return the public download link in markdown
    # Note: Using Typebot's ngrok address to match original configuration
    download_url = f"https://nonrebellious-homer-bigamously.ngrok-free.dev/download_pdf/{session_id}"
    return {"message": download_url}

@app.get("/download_pdf/{session_id}")
def download_pdf(session_id: str):
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("SELECT pdf_path, vorname, nachname FROM applications WHERE session_id = ?", (session_id,))
        row = c.fetchone()
        conn.close()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database query error: {str(e)}")
        
    if not row:
        raise HTTPException(status_code=404, detail="Application not found")
        
    pdf_path, vorname, nachname = row
    if not os.path.exists(pdf_path):
        raise HTTPException(status_code=404, detail="PDF file not found on disk")
        
    filename = f"Antrag_Pflege_{vorname}_{nachname}.pdf".replace(" ", "_")
    return FileResponse(path=pdf_path, media_type="application/pdf", filename=filename)

@app.get("/")
def root():
    return {"ok": True}

@app.get("/admin", response_class=HTMLResponse)
def admin_dashboard(username: str = Depends(require_admin)):
    """Admin dashboard to view all submitted applications and download filled PDFs."""
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        c.execute("""
            SELECT id, session_id, vorname, nachname, email_adresse,
                   hilfe_art, einrichtung_name, aufnahme_datum,
                   created_at, pdf_path
            FROM applications
            ORDER BY created_at DESC
        """)
        rows = c.fetchall()
        conn.close()
    except Exception as e:
        return HTMLResponse(f"<h1>Datenbankfehler</h1><p>{e}</p>", status_code=500)

    rows_html = ""
    for r in rows:
        pdf_exists = os.path.exists(r['pdf_path']) if r['pdf_path'] else False
        download_btn = (
            f'<a href="/download_pdf/{r["session_id"]}" '
            f'style="background:#4f46e5;color:#fff;padding:6px 14px;border-radius:6px;text-decoration:none;font-size:13px;">'
            f'PDF herunterladen</a>'
            if pdf_exists else '<span style="color:#9ca3af;font-size:13px;">PDF nicht gefunden</span>'
        )
        rows_html += f"""
        <tr>
          <td>{r['id']}</td>
          <td><strong>{r['vorname']} {r['nachname']}</strong></td>
          <td>{r['email_adresse'] or '-'}</td>
          <td>{r['hilfe_art'] or '-'}</td>
          <td>{r['einrichtung_name'] or '-'}</td>
          <td>{r['aufnahme_datum'] or '-'}</td>
          <td>{r['created_at'][:16] if r['created_at'] else '-'}</td>
          <td>{download_btn}</td>
        </tr>"""

    html = f"""
    <!DOCTYPE html>
    <html lang="de">
    <head>
      <meta charset="UTF-8">
      <title>Antrag Admin-Dashboard</title>
      <style>
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{ font-family: 'Segoe UI', sans-serif; background: #f1f5f9; color: #1e293b; }}
        header {{ background: linear-gradient(135deg,#4f46e5,#7c3aed); color: white;
                  padding: 24px 40px; }}
        header h1 {{ font-size: 1.6rem; }}
        header p {{ opacity: .8; font-size: .9rem; margin-top: 4px; }}
        .container {{ padding: 32px 40px; }}
        .stats {{ display: flex; gap: 20px; margin-bottom: 28px; }}
        .stat-card {{ background: white; border-radius: 12px; padding: 20px 28px;
                      box-shadow: 0 1px 4px rgba(0,0,0,.08); flex: 1; }}
        .stat-card h2 {{ font-size: 2rem; color: #4f46e5; }}
        .stat-card p {{ color: #64748b; font-size: .85rem; margin-top: 4px; }}
        table {{ width: 100%; border-collapse: collapse; background: white;
                 border-radius: 12px; overflow: hidden;
                 box-shadow: 0 1px 4px rgba(0,0,0,.08); }}
        th {{ background: #4f46e5; color: white; padding: 12px 16px;
              text-align: left; font-size: .82rem; text-transform: uppercase;
              letter-spacing: .05em; }}
        td {{ padding: 12px 16px; border-bottom: 1px solid #f1f5f9; font-size: .88rem; }}
        tr:last-child td {{ border-bottom: none; }}
        tr:hover td {{ background: #f8fafc; }}
        .empty {{ text-align: center; padding: 60px; color: #94a3b8; }}
      </style>
    </head>
    <body>
      <header>
        <h1>&#128196; Antrag Admin-Dashboard</h1>
        <p>Hilfe zur Pflege &mdash; Alle eingereichten Antr&auml;ge</p>
      </header>
      <div class="container">
        <div class="stats">
          <div class="stat-card"><h2>{len(rows)}</h2><p>Eingereichte Antr&auml;ge</p></div>
          <div class="stat-card"><h2>{sum(1 for r in rows if r['pdf_path'] and os.path.exists(r['pdf_path']))}</h2><p>PDFs verf&uuml;gbar</p></div>
        </div>
        {'<table><thead><tr><th>#</th><th>Name</th><th>E-Mail</th><th>Art der Hilfe</th><th>Einrichtung</th><th>Aufnahme</th><th>Eingereicht</th><th>Aktion</th></tr></thead><tbody>' + rows_html + '</tbody></table>' if rows else '<div class="empty"><p>&#128203; Noch keine Antr&auml;ge eingereicht.</p></div>'}
      </div>
    </body>
    </html>
    """
    return HTMLResponse(html)

@app.post("/ask")
def ask(body: AskBody, request: Request):
    lang = (body.language or "de").lower().strip()
    original_question = body.question.strip()
    #  Resolve Session ID: If Typebot sends None/null/empty, fallback to client IP!
    sid = body.session_id
    if not sid or str(sid).strip() == "" or str(sid).strip().lower() in ["none", "null"]:
        client_ip = request.client.host if (request and request.client and request.client.host) else "default_client"
        sid = f"client_{client_ip}"
        
    print(f"INCOMING QUESTION ({lang}): {original_question} | Session Resolved: {sid}", flush=True)

    try:
        import re

        # ── 0. CRISIS CHECK (must run BEFORE everything else) ──────────────
        if is_crisis(original_question):
            print(f"⚠️  CRISIS DETECTED for session {sid}: {original_question}", flush=True)
            crisis_text = CRISIS_RESPONSES.get(lang, CRISIS_RESPONSE_DE)
            if sid:
                if sid not in chat_histories:
                    chat_histories[sid] = []
                chat_histories[sid].append({"role": "user",      "content": original_question})
                chat_histories[sid].append({"role": "assistant", "content": crisis_text})
            return {"answer": crisis_text, "sources": []}

        # 1. Dynamic User Name Extraction from Message
        new_name = extract_user_name(original_question)
        if new_name and sid:
            session_user_names[sid] = new_name
            print(f"UPDATED USER NAME FOR SESSION {sid}: {new_name}", flush=True)

        # 2. Topic Filtering Guardrail (reject general questions like "wo liegt berlin?")
        if not is_allowed_topic(original_question):
            print(f"REJECTED OFF-TOPIC QUESTION: {original_question}", flush=True)
            fallback_msgs = {
                "de": "Ich kann nur Fragen zum Thema Hilfe zur Pflege beantworten.",
                "en": "I can only answer questions about Care Assistance.",
                "fr": "Je peux uniquement répondre aux questions concernant l'Aide aux Soins.",
                "ar": "يمكنني فقط الإجابة عن الأسئلة المتعلقة بطلب المساعدة في الرعاية."
            }
            refusal_text = fallback_msgs.get(lang, fallback_msgs["de"])
            
            if sid:
                if sid not in chat_histories:
                    chat_histories[sid] = []
                chat_histories[sid].append({"role": "user", "content": original_question})
                chat_histories[sid].append({"role": "assistant", "content": refusal_text})
                
            return {"answer": refusal_text, "sources": []}

        # 3. Direct Pure Name Recall Query Handling (e.g. "wie heiße ich?")
        if is_name_recall_query(original_question):
            stored_name = session_user_names.get(sid) if sid else None
            if not stored_name and sid and sid in chat_histories:
                for turn in chat_histories[sid]:
                    if turn["role"] == "user":
                        extracted = extract_user_name(turn["content"])
                        if extracted:
                            stored_name = extracted
                            session_user_names[sid] = stored_name
                            break
            
            if stored_name:
                name_responses = {
                    "de": f"Du heißt {stored_name}.",
                    "en": f"Your name is {stored_name}.",
                    "fr": f"Vous vous appelez {stored_name}.",
                    "ar": f"اسمك هو {stored_name}."
                }
                answer_text = name_responses.get(lang, name_responses["de"])
            else:
                unknown_responses = {
                    "de": "Sie haben mir Ihren Namen noch nicht genannt. Wie heißen Sie?",
                    "en": "You haven't told me your name yet. What is your name?",
                    "fr": "Vous ne m'avez pas encore indiqué votre nom. Comment vous appelez-vous ?",
                    "ar": "لم تخبرني باسمك بعد. ما هو اسمك؟"
                }
                answer_text = unknown_responses.get(lang, unknown_responses["de"])

            if sid:
                if sid not in chat_histories:
                    chat_histories[sid] = []
                chat_histories[sid].append({"role": "user", "content": original_question})
                chat_histories[sid].append({"role": "assistant", "content": answer_text})

            return {"answer": answer_text, "sources": []}

        # 4. Pure Greeting / Introduction Messages (e.g. "Hallo, mein Name ist Lamiae.")
        def has_care_keywords(text: str) -> bool:
            q = text.lower()
            ck = [
                "pflege", "pflegegrad", "hilfe zur pflege", "antrag", "pflegekasse", 
                "versicherung", "medizinisch", "care", "sozialhilfe", "nachrang", 
                "einkommen", "vermögen", "eigenanteil", "kosten", "heimkosten", 
                "zuzahlung", "unterhalt", "sgb", "dokument", "dokumente", "unterlagen", 
                "nachweis", "formular", "ausfüllen", "apply", "document", "documents", 
                "hilfebedürftig", "einrichtung", "betreuung", "hildesheim", "landkreis",
                "vorsorgevollmacht", "patientenverfügung", "heim", "pflegedienst"
            ]
            return any(k in q for k in ck)

        if new_name and not has_care_keywords(original_question):
            intro_responses = {
                "de": f"Hallo {new_name}! Wie kann ich Ihnen bei Fragen zur Hilfe zur Pflege helfen?",
                "en": f"Hello {new_name}! How can I help you with Care Assistance questions?",
                "fr": f"Bonjour {new_name} ! Comment puis-je vous aider pour les questions concernant l'Aide aux Soins ?",
                "ar": f"مرحباً {new_name}! كيف يمكنني مساعدتك في الأسئلة المتعلقة بطلب المساعدة في الرعاية؟"
            }
            intro_text = intro_responses.get(lang, intro_responses["de"])
            if sid:
                if sid not in chat_histories:
                    chat_histories[sid] = []
                chat_histories[sid].append({"role": "user", "content": original_question})
                chat_histories[sid].append({"role": "assistant", "content": intro_text})
            return {"answer": intro_text, "sources": []}

        # 4. Care & RAG Questions
        if lang != "de":
            german_question = translate_locally(original_question, from_lang=lang, to_lang="de")
        else:
            german_question = original_question

        raw_answer, docs = ask_rag(
            german_question, 
            session_id=sid, 
            language=lang, 
            user_display_text=original_question
        )

        return {"answer": raw_answer, "sources": docs}
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"ERROR: {error_details}", flush=True)
        return {"answer": f"Technical error: {str(e)}", "sources": []}
