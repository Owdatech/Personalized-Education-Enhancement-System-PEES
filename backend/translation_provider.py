import os
# translation_provider.py
from deep_translator import GoogleTranslator
from functools import lru_cache
import threading, re, time, hashlib

_ar = re.compile(r'[\u0600-\u06FF]')
_lock = threading.Lock()

@lru_cache(maxsize=5000)
def _cached_translate_en_to_ar(s: str) -> str:
    with _lock:
        # Basic throttle to avoid being rate-limited
        time.sleep(0.05)
        return GoogleTranslator(source="en", target="ar").translate(s)

def translate_text_ar(text: str) -> str:
    if not isinstance(text, str) or not text.strip():
        return text
    res = _cached_translate_en_to_ar(text.strip())
    return res

def contains_arabic(block: dict) -> bool:
    def has_ar(x): return isinstance(x, str) and bool(_ar.search(x))
    for k in ("strengths","weaknesses","interventions","recommendations"):
        for v in (block.get(k) or []):
            if has_ar(v): 
                return True
    return False

def translate_analysis_recursively(obj):
    if isinstance(obj, dict):
        return {k: translate_analysis_recursively(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [translate_analysis_recursively(v) for v in obj]
    if isinstance(obj, str):
        return translate_text_ar(obj)
    return obj
