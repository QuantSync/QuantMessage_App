import os
import requests
from pypdf import PdfReader
from PIL import Image

def parse_pdf_from_url(url: str) -> str:
    """Downloads a PDF from a URL and extracts text using pure-python pypdf."""
    text_content = []
    temp_path = "temp_download.pdf"
    try:
        response = requests.get(url, stream=True)
        if response.status_code == 200:
            with open(temp_path, 'wb') as f:
                f.write(response.content)
                
            reader = PdfReader(temp_path)
            pages_to_read = min(len(reader.pages), 10) # Limit to 10 pages for safety
            
            for page_num in range(pages_to_read):
                page = reader.pages[page_num]
                text_content.append(f"--- Page {page_num + 1} ---\n{page.extract_text() or ''}")
            
            os.remove(temp_path)
            return "\n".join(text_content)
        else:
            return f"Failed to download PDF: Status {response.status_code}"
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return f"Error parsing PDF: {str(e)}"

def parse_image(file_path: str) -> str:
    """
    For advanced OCR, you would use pytesseract or an external API.
    Since we don't know if Tesseract is installed, we return a system prompt
    advising the Multi-Agent system to use an LLM vision API or ask the user.
    """
    try:
        # Just verifying it's a valid image
        img = Image.open(file_path)
        img.verify()
        return f"[Image uploaded: {os.path.basename(file_path)}. Agent: Please use your built-in vision capabilities to analyze this image, or use the search_web tool if OCR is needed.]"
    except Exception as e:
        return f"Error verifying image: {str(e)}"
