"""
vector_store.py – FAISS semantic search trên 2473 món ăn.
Dùng model đa ngữ để tìm món liên quan nhất theo câu hỏi tiếng Việt.
"""
import os
import pickle
import numpy as np

# Lazy imports để tránh lỗi khi chưa cài
_faiss = None
_SentenceTransformer = None

def _import_deps():
    global _faiss, _SentenceTransformer
    if _faiss is None:
        import faiss
        _faiss = faiss
    if _SentenceTransformer is None:
        from sentence_transformers import SentenceTransformer
        _SentenceTransformer = SentenceTransformer

CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".vector_cache")
INDEX_PATH = os.path.join(CACHE_DIR, "faiss.index")
META_PATH  = os.path.join(CACHE_DIR, "meta.pkl")
MODEL_NAME = "paraphrase-multilingual-MiniLM-L12-v2"

_index = None
_meta  = None   # list of dish_id matching index positions
_model = None


def _get_model():
    global _model
    if _model is None:
        _import_deps()
        print(f"[vector_store] Loading embedding model: {MODEL_NAME}")
        _model = _SentenceTransformer(MODEL_NAME)
    return _model


def build_index(rag_df):
    """Tạo FAISS index từ cột rag_context. Lưu cache để khởi động lại nhanh."""
    global _index, _meta
    _import_deps()
    os.makedirs(CACHE_DIR, exist_ok=True)

    # Nếu cache tồn tại → load
    if os.path.exists(INDEX_PATH) and os.path.exists(META_PATH):
        print("[vector_store] Loading cached FAISS index...")
        _index = _faiss.read_index(INDEX_PATH)
        with open(META_PATH, "rb") as f:
            _meta = pickle.load(f)
        print(f"[vector_store] Index ready: {_index.ntotal} vectors")
        return

    print("[vector_store] Building FAISS index (first time, ~1-2 min)...")
    model  = _get_model()
    texts  = rag_df['rag_context'].fillna("").tolist()
    ids    = rag_df['dish_id'].tolist()

    # Encode in batches
    batch  = 128
    vecs   = []
    for i in range(0, len(texts), batch):
        chunk = texts[i:i+batch]
        vecs.append(model.encode(chunk, show_progress_bar=False))
        if i % 1000 == 0:
            print(f"  Encoded {i}/{len(texts)}...")

    matrix = np.vstack(vecs).astype("float32")
    dim    = matrix.shape[1]

    index  = _faiss.IndexFlatIP(dim)   # Inner Product = cosine sau khi normalize
    _faiss.normalize_L2(matrix)
    index.add(matrix)

    _faiss.write_index(index, INDEX_PATH)
    with open(META_PATH, "wb") as f:
        pickle.dump(ids, f)

    _index = index
    _meta  = ids
    print(f"[vector_store] Built index with {index.ntotal} vectors. Cached.")


def semantic_search(query: str, k: int = 8) -> list[str]:
    """Trả về list dish_id phù hợp nhất với câu hỏi."""
    if _index is None:
        return []
    model = _get_model()
    vec   = model.encode([query]).astype("float32")
    _faiss.normalize_L2(vec)
    _, I  = _index.search(vec, k)
    return [_meta[i] for i in I[0] if 0 <= i < len(_meta)]
