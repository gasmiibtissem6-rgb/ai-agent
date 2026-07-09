import os
import re
import hashlib
from datetime import datetime

import qrcode

from reportlab.lib import colors
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    PageBreak,
    Table,
    TableStyle,
    Image,
)

OUTPUT_DIR = "generated_pdfs"
QR_DIR = "generated_qrcodes"


def clean_filename(text: str) -> str:
    text = re.sub(
        r"[^a-zA-Z0-9_àâäéèêëïîôöùûüçÀÂÄÉÈÊËÏÎÔÖÙÛÜÇ-]",
        "_",
        text,
    )
    return text[:80]


def format_title(title: str) -> str:
    words = title.upper().split()
    if len(words) > 6:
        middle = len(words) // 2
        return " ".join(words[:middle]) + "<br/>" + " ".join(words[middle:])
    return title.upper()


def normalize_content(content: str) -> str:
    content = content.replace("\\n", "\n")

    content = re.sub(
        r"^\s*,\s*il a été convenu ce qui suit\s*:\s*",
        "",
        content,
        flags=re.IGNORECASE,
    )

    content = content.replace("ENTRE LES SOUSSIGNÉS", "\nENTRE LES SOUSSIGNÉS\n")

    for i in range(1, 30):
        content = content.replace(f"Article {i}", f"\n\nArticle {i}")

    content = content.replace("Fait à", "\n\nFait à")
    content = content.replace("Signature du Client", "\n\nSignature du Client")
    content = content.replace("Signature du Prestataire", "\n\nSignature du Prestataire")

    return content.strip()


def split_article(line: str):
    match = re.match(r"^(Article\s+\d+\s*[-–]\s*[^:]+)\s*:\s*(.*)$", line)
    if match:
        return match.group(1).strip(), match.group(2).strip()
    return line.strip(), ""


def generate_qr_code(contract_number: str, title: str, content: str) -> str:
    os.makedirs(QR_DIR, exist_ok=True)

    qr_path = os.path.join(QR_DIR, f"{contract_number}.png")
    document_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()[:16]

    qr_data = (
        f"IDEAL AI CONTRACT\n"
        f"Contrat: {contract_number}\n"
        f"Titre: {title}\n"
        f"Hash: {document_hash}"
    )

    qr = qrcode.QRCode(
        version=2,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(qr_path)

    return qr_path


def header_footer(canvas, doc):
    canvas.saveState()

    width, height = A4

    # Header
    canvas.setFillColor(HexColor("#1A237E"))
    canvas.setFont("Helvetica-Bold", 9)
    canvas.drawString(2 * cm, height - 1.2 * cm, "IDEAL AI CONTRACT")

    canvas.setFillColor(colors.lightgrey)
    canvas.rect(2 * cm, height - 1.45 * cm, width - 4 * cm, 0.02 * cm, fill=1, stroke=0)

    # Watermark
    canvas.setFillColor(HexColor("#F2F4F8"))
    canvas.setFont("Helvetica-Bold", 42)
    canvas.saveState()
    canvas.translate(width / 2, height / 2)
    canvas.rotate(35)
    canvas.drawCentredString(0, 0, "CONFIDENTIEL")
    canvas.restoreState()

    # Footer
    canvas.setFillColor(colors.grey)
    canvas.setFont("Helvetica", 8)
    canvas.drawString(2 * cm, 1.2 * cm, "IDEAL Smart Contract Agent · Document confidentiel")
    canvas.drawRightString(width - 2 * cm, 1.2 * cm, f"Page {doc.page}")

    canvas.restoreState()


def signature_box(title: str):
    sig_title = ParagraphStyle(
        "sig_title",
        fontName="Helvetica-Bold",
        fontSize=10,
        textColor=HexColor("#0D47A1"),
    )

    sig_small = ParagraphStyle(
        "sig_small",
        fontName="Helvetica",
        fontSize=8,
        textColor=colors.grey,
    )

    return Table(
        [
            [Paragraph(title, sig_title)],
            [""],
            [Paragraph("Nom : ____________________", sig_small)],
            [Paragraph("Date : ____________________", sig_small)],
        ],
        colWidths=[7.2 * cm],
        rowHeights=[0.7 * cm, 2 * cm, 0.45 * cm, 0.45 * cm],
        style=TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.8, HexColor("#90CAF9")),
                ("BACKGROUND", (0, 0), (-1, -1), HexColor("#F8FBFF")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("PADDING", (0, 0), (-1, -1), 8),
            ]
        ),
    )


def article_header(title: str):
    return Table(
        [[Paragraph(title.upper(), ParagraphStyle(
            "article_header",
            fontName="Helvetica-Bold",
            fontSize=10.5,
            textColor=HexColor("#0D47A1"),
            leading=14,
        ))]],
        colWidths=[16 * cm],
        style=TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), HexColor("#E3F2FD")),
                ("BOX", (0, 0), (-1, -1), 0.6, HexColor("#90CAF9")),
                ("PADDING", (0, 0), (-1, -1), 8),
            ]
        ),
    )


def qr_block(qr_path: str, contract_number: str, styles: dict):
    qr_img = Image(qr_path, width=3 * cm, height=3 * cm)

    return Table(
        [
            [Paragraph("<b>QR Code de vérification</b>", styles["heading"])],
            [qr_img],
            [Paragraph(f"Référence : {contract_number}", styles["center"])],
        ],
        colWidths=[7 * cm],
        style=TableStyle(
            [
                ("BOX", (0, 0), (-1, -1), 0.8, HexColor("#BBDEFB")),
                ("BACKGROUND", (0, 0), (-1, -1), HexColor("#F8FBFF")),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("PADDING", (0, 0), (-1, -1), 8),
            ]
        ),
    )


def generate_pdf(title: str, content: str) -> str:
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    contract_number = "CT-" + datetime.now().strftime("%Y%m%d%H%M%S")
    qr_path = generate_qr_code(contract_number, title, content)

    filename = (
        clean_filename(title.replace(" ", "_"))
        + "_"
        + datetime.now().strftime("%Y%m%d_%H%M%S")
        + ".pdf"
    )

    filepath = os.path.join(OUTPUT_DIR, filename)

    doc = SimpleDocTemplate(
        filepath,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2.2 * cm,
        bottomMargin=2 * cm,
        title=title,
        author="IDEAL Smart Contract Agent",
        subject="Contrat généré automatiquement",
    )

    styles = {
        "cover_title": ParagraphStyle(
            "cover_title",
            fontName="Helvetica-Bold",
            fontSize=22,
            leading=30,
            alignment=TA_CENTER,
            textColor=HexColor("#1A237E"),
            spaceAfter=30,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=18,
            alignment=TA_CENTER,
            textColor=HexColor("#0D47A1"),
            spaceAfter=12,
        ),
        "heading": ParagraphStyle(
            "heading",
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=16,
            textColor=HexColor("#0D47A1"),
            spaceBefore=10,
            spaceAfter=8,
        ),
        "normal": ParagraphStyle(
            "normal",
            fontName="Helvetica",
            fontSize=10,
            leading=15,
            alignment=TA_LEFT,
            textColor=HexColor("#111111"),
            spaceAfter=7,
        ),
        "center": ParagraphStyle(
            "center",
            fontName="Helvetica",
            fontSize=9,
            leading=13,
            alignment=TA_CENTER,
            textColor=colors.grey,
        ),
    }

    story = []

    # Couverture
    story.append(Spacer(1, 2.6 * cm))
    story.append(Paragraph(format_title(title), styles["cover_title"]))
    story.append(Spacer(1, 1 * cm))
    story.append(Paragraph("DOCUMENT CONTRACTUEL", styles["subtitle"]))
    story.append(Paragraph(datetime.now().strftime("%d/%m/%Y"), styles["subtitle"]))
    story.append(Spacer(1, 2 * cm))

    summary_table = Table(
        [
            ["Numéro du contrat", contract_number],
            ["Type de document", "Contrat"],
            ["Statut", "Généré automatiquement"],
            ["Système", "IDEAL Smart Contract Agent"],
        ],
        colWidths=[6 * cm, 8 * cm],
    )

    summary_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), HexColor("#E3F2FD")),
                ("TEXTCOLOR", (0, 0), (-1, -1), HexColor("#0D47A1")),
                ("FONTNAME", (0, 0), (-1, -1), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("BOX", (0, 0), (-1, -1), 0.5, HexColor("#BBDEFB")),
                ("INNERGRID", (0, 0), (-1, -1), 0.5, HexColor("#BBDEFB")),
                ("PADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )

    story.append(summary_table)
    story.append(PageBreak())

    # Corps
    normalized = normalize_content(content)

    for line in normalized.split("\n"):
        line = line.strip()

        if not line:
            story.append(Spacer(1, 0.15 * cm))
            continue

        if line.startswith("Article"):
            article_title, article_text = split_article(line)

            story.append(Spacer(1, 0.3 * cm))
            story.append(article_header(article_title))

            if article_text:
                story.append(Spacer(1, 0.2 * cm))
                story.append(Paragraph(article_text, styles["normal"]))

        elif line.startswith("ENTRE LES SOUSSIGNÉS"):
            story.append(Paragraph("ENTRE LES SOUSSIGNÉS", styles["heading"]))
            story.append(
                Paragraph(
                    "Le Client et le Prestataire, ci-après désignés collectivement les « Parties », "
                    "ont convenu ce qui suit :",
                    styles["normal"],
                )
            )

        elif line.startswith("Fait à") or line.startswith("Date"):
            story.append(Spacer(1, 0.4 * cm))
            story.append(Paragraph(line, styles["heading"]))

        elif line.startswith("Signature"):
            continue

        else:
            story.append(Paragraph(line, styles["normal"]))

    story.append(Spacer(1, 1 * cm))

    # QR + signatures
    story.append(qr_block(qr_path, contract_number, styles))
    story.append(Spacer(1, 1 * cm))

    signatures = Table(
        [
            [
                signature_box("Signature du Client"),
                signature_box("Signature du Prestataire"),
            ]
        ],
        colWidths=[8 * cm, 8 * cm],
    )

    signatures.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ]
        )
    )

    story.append(signatures)

    doc.build(
        story,
        onFirstPage=header_footer,
        onLaterPages=header_footer,
    )

    return f"PDF généré avec succès : {filepath}"
