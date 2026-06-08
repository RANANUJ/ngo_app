import markdown2
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import simpleSplit
import os

# Paths
md_path = "NGO_Connect_Complete_Documentation.md"
pdf_path = "NGO_Connect_Complete_Documentation.pdf"

# Read markdown content
with open(md_path, 'r', encoding='utf-8') as f:
    md_content = f.read()

# Convert markdown to plain text (for simple PDF)
plain_text = markdown2.markdown(md_content)
plain_text = plain_text.replace('<p>', '').replace('</p>', '\n').replace('<br>', '\n').replace('<br/>', '\n')

# Create PDF
c = canvas.Canvas(pdf_path, pagesize=letter)
width, height = letter
margin = 40
textobject = c.beginText(margin, height - margin)
textobject.setFont("Helvetica", 11)

lines = simpleSplit(plain_text, "Helvetica", 11, width - 2*margin)
for line in lines:
    if textobject.getY() < margin:
        c.drawText(textobject)
        c.showPage()
        textobject = c.beginText(margin, height - margin)
        textobject.setFont("Helvetica", 11)
    textobject.textLine(line)
c.drawText(textobject)
c.save()

print(f"PDF generated: {os.path.abspath(pdf_path)}")
