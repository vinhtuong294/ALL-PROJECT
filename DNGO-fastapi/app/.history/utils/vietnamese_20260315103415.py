import re

def remove_accents(text: str) -> str:
    """Bỏ dấu tiếng Việt"""
    if not text:
        return text
    
    accents = {
        'a': 'àáảãạăằắẳẵặâầấẩẫậ',
        'e': 'èéẻẽẹêềếểễệ',
        'i': 'ìíỉĩị',
        'o': 'òóỏõọôồốổỗộơờớởỡợ',
        'u': 'ùúủũụưừứửữự',
        'y': 'ỳýỷỹỵ',
        'd': 'đ',
        'A': 'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬ',
        'E': 'ÈÉẺẼẸÊỀẾỂỄỆ',
        'I': 'ÌÍỈĨỊ',
        'O': 'ÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ',
        'U': 'ÙÚỦŨỤƯỪỨỬỮỰ',
        'Y': 'ỲÝỶỸỴ',
        'D': 'Đ'
    }
    
    result = text
    for ascii_char, viet_chars in accents.items():
        for viet_char in viet_chars:
            result = result.replace(viet_char, ascii_char)
    
    return result


def create_search_pattern(search: str) -> str:
    """Tạo pattern search cho cả có dấu và không dấu"""
    if not search:
        return search
    
    accents_map = {
        'a': '[aàáảãạăằắẳẵặâầấẩẫậ]',
        'e': '[eèéẻẽẹêềếểễệ]',
        'i': '[iìíỉĩị]',
        'o': '[oòóỏõọôồốổỗộơờớởỡợ]',
        'u': '[uùúủũụưừứửữự]',
        'y': '[yỳýỷỹỵ]',
        'd': '[dđ]',
    }
    
    pattern = ''
    for char in search.lower():
        if char in accents_map:
            pattern += accents_map[char]
        else:
            pattern += char
    
    return pattern