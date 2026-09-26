import chromadb
import fitz  # PyMuPDF
import sys
import uuid
import os

# =====================================================================
# 1. SETUP PDF PATH HERE
# Replace this string with the actual folder path where your PDFs are.
# =====================================================================
PDF_FOLDER = "./PDF"
if not os.path.exists(PDF_FOLDER) or not any(f.lower().endswith('.pdf') for f in os.listdir(PDF_FOLDER)):
    PDF_FOLDER = "/Users/benyousseflamiae/Desktop/typebot/IT/PDF"

def chunk_text(text, chunk_size=800, overlap=100):
    """
    Splits a large text into smaller overlapping chunks.
    This helps the RAG model find the exact relevant section.
    """
    words = text.split()
    chunks = []
    i = 0
    while i < len(words):
        chunk_words = words[i:i + chunk_size]
        chunk_text = " ".join(chunk_words)
        chunks.append(chunk_text)
        i += chunk_size - overlap
    return chunks

def main():
    if not os.path.exists(PDF_FOLDER):
        print(f"ERROR: Could not find the folder at {PDF_FOLDER}")
        sys.exit(1)

    print("Connecting to ChromaDB database './chroma_db'...")
    client = chromadb.PersistentClient(path="./chroma_db")
    collection = client.get_or_create_collection(name="pflege_docs")

    pdf_files = [f for f in os.listdir(PDF_FOLDER) if f.lower().endswith('.pdf')]
    if not pdf_files:
        print(f"No PDF files found in {PDF_FOLDER}")
        sys.exit(1)

    documents = []
    metadatas = []
    ids = []

    for pdf_file in pdf_files:
        pdf_path = os.path.join(PDF_FOLDER, pdf_file)
        print(f"Opening PDF: {pdf_path}")
        
        try:
            doc = fitz.open(pdf_path)
        except Exception as e:
            print(f"Failed to open PDF {pdf_file}: {e}")
            continue

        full_text = ""
        for page_num, page in enumerate(doc):
            text = page.get_text()
            full_text += text + "\n"

        print(f"Extracted {len(full_text)} characters from {len(doc)} pages of {pdf_file}.")

        chunks = chunk_text(full_text, chunk_size=200, overlap=40)
        print(f"Split {pdf_file} into {len(chunks)} overlapping chunks.")

        for i, chunk in enumerate(chunks):
            documents.append(chunk)
            metadatas.append({"source": pdf_file, "chunk": i})
            ids.append(str(uuid.uuid4()))

    print(f"Total chunks to insert: {len(documents)}")

    print("Generating embeddings and inserting into ChromaDB...")
    batch_size = 100
    for i in range(0, len(documents), batch_size):
        end = i + batch_size
        collection.add(
            documents=documents[i:end],
            metadatas=metadatas[i:end],
            ids=ids[i:end]
        )
        print(f"  Inserted batch {i//batch_size + 1}...")

    print("Success! Your PDF data has been ingested and embedded into ChromaDB.")
    print("You can now ask your Chatbot questions about these PDFs!")

if __name__ == "__main__":
    main()
