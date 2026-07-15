# book/compile.py
import os
import re

LESSONS_DIR = "../lessons"
OUTPUT_DIR = "."
BOOK_MD = "book.md"
BOOK_HTML = "book.html"

def get_lessons():
    # Sort files naturally
    files = [f for f in os.listdir(LESSONS_DIR) if f.endswith(".md")]
    return sorted(files)

def compile_book():
    print("Compiling book chapters...")
    lessons = get_lessons()
    
    merged_md = []
    
    # 1. Add Cover page markup
    cover_html = """<div class="cover-page">
  <h1>Enterprise AI Engineering with Amazon Bedrock</h1>
  <div class="cover-subtitle">Architecting Transferable Multi-Cloud Patterns (2026 Edition)</div>
  <div class="cover-author">Nextware Systems</div>
  <div class="cover-date">July 2026</div>
</div>

"""
    merged_md.append(cover_html)
    
    # 2. Add Table of Contents Placeholder
    merged_md.append("# Table of Contents\n\n[TOC]\n\n")
    
    # 3. Concatenate chapters
    for filename in lessons:
        filepath = os.path.join(LESSONS_DIR, filename)
        print(f"Reading {filename}...")
        
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            
            # Clean up absolute file:// links to make the book clean
            content = re.sub(r'file:///Users/prakash/Work/amazon-bedrock-masterclass/', '', content)
            content = re.sub(r'file:///Users/prakash/.gemini/antigravity-ide/brain/[^/]+/', '', content)
            
            # Append page break before each chapter
            merged_md.append("\n<div style='page-break-before: always;'></div>\n\n")
            merged_md.append(content)
            
    # Write merged Markdown
    output_md_path = os.path.join(OUTPUT_DIR, BOOK_MD)
    with open(output_md_path, "w", encoding="utf-8") as f:
        f.write("\n".join(merged_md))
        
    print(f"Consolidated markdown written to {output_md_path}")
    
    # Generate HTML from Markdown using standard library or simple replacement for tags
    # Let's write a simple HTML exporter that bundles the stylesheet
    try:
        import markdown
        with open(output_md_path, "r", encoding="utf-8") as f:
            text = f.read()
            html_content = markdown.markdown(text, extensions=['toc', 'tables', 'fenced_code'])
            
        full_html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Enterprise AI Engineering with Amazon Bedrock (2026)</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  {html_content}
</body>
</html>"""
        
        output_html_path = os.path.join(OUTPUT_DIR, BOOK_HTML)
        with open(output_html_path, "w", encoding="utf-8") as f:
            f.write(full_html)
        print(f"Print-ready HTML written to {output_html_path}")
        
    except ImportError:
        print("Warning: python-markdown library not found. Run 'pip install markdown' to compile HTML.")

if __name__ == "__main__":
    # Ensure current dir is book/
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    compile_book()
