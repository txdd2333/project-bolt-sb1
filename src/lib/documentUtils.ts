import mammoth from 'mammoth';
import TurndownService from 'turndown';
import { marked } from 'marked';
import { Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell, WidthType } from 'docx';
import { saveAs } from 'file-saver';

const turndownService = new TurndownService({
  headingStyle: 'atx',
  codeBlockStyle: 'fenced',
  bulletListMarker: '-',
});

turndownService.addRule('strikethrough', {
  filter: ['del', 's'] as (keyof HTMLElementTagNameMap)[],
  replacement: (content) => `~~${content}~~`,
});

export type ImportFormat = 'txt' | 'md' | 'docx';
export type ExportFormat = 'txt' | 'md' | 'docx' | 'html';

export async function importDocument(file: File): Promise<string> {
  const fileName = file.name.toLowerCase();

  if (fileName.endsWith('.docx')) {
    return importDocx(file);
  } else if (fileName.endsWith('.md') || fileName.endsWith('.markdown')) {
    return importMarkdown(file);
  } else if (fileName.endsWith('.txt')) {
    return importText(file);
  } else if (fileName.endsWith('.html') || fileName.endsWith('.htm')) {
    return importHtml(file);
  }

  throw new Error('不支持的文件格式。支持的格式：.txt, .md, .docx, .html');
}

async function importDocx(file: File): Promise<string> {
  const arrayBuffer = await file.arrayBuffer();
  const result = await mammoth.convertToHtml({ arrayBuffer });
  return result.value || '<p></p>';
}

async function importMarkdown(file: File): Promise<string> {
  const text = await file.text();
  const html = await marked(text);
  return html || '<p></p>';
}

async function importText(file: File): Promise<string> {
  const text = await file.text();
  const paragraphs = text.split(/\n\n+/).filter(p => p.trim());
  if (paragraphs.length === 0) return '<p></p>';
  return paragraphs.map(p => `<p>${p.replace(/\n/g, '<br>')}</p>`).join('');
}

async function importHtml(file: File): Promise<string> {
  const html = await file.text();
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  return bodyMatch ? bodyMatch[1] : html;
}

export function exportDocument(html: string, format: ExportFormat, fileName: string): void {
  switch (format) {
    case 'txt':
      exportAsText(html, fileName);
      break;
    case 'md':
      exportAsMarkdown(html, fileName);
      break;
    case 'docx':
      exportAsDocx(html, fileName);
      break;
    case 'html':
      exportAsHtml(html, fileName);
      break;
    default:
      throw new Error('不支持的导出格式');
  }
}

function htmlToPlainText(html: string): string {
  const temp = document.createElement('div');
  temp.innerHTML = html;

  const blocks = temp.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, tr, div');
  blocks.forEach(block => {
    block.insertAdjacentText('afterend', '\n');
  });

  const brs = temp.querySelectorAll('br');
  brs.forEach(br => {
    br.replaceWith('\n');
  });

  return (temp.textContent || temp.innerText || '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function htmlToMarkdown(html: string): string {
  return turndownService.turndown(html);
}

function exportAsText(html: string, fileName: string): void {
  const text = htmlToPlainText(html);
  const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
  saveAs(blob, `${fileName}.txt`);
}

function exportAsMarkdown(html: string, fileName: string): void {
  const markdown = htmlToMarkdown(html);
  const blob = new Blob([markdown], { type: 'text/markdown;charset=utf-8' });
  saveAs(blob, `${fileName}.md`);
}

function exportAsHtml(html: string, fileName: string): void {
  const fullHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${fileName}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.6; }
    h1, h2, h3 { color: #333; }
    table { border-collapse: collapse; width: 100%; margin: 16px 0; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background-color: #f5f5f5; }
    code { background-color: #f5f5f5; padding: 2px 6px; border-radius: 4px; }
    pre { background-color: #f5f5f5; padding: 16px; border-radius: 8px; overflow-x: auto; }
    blockquote { border-left: 4px solid #ddd; margin: 16px 0; padding-left: 16px; color: #666; }
    img { max-width: 100%; }
  </style>
</head>
<body>
${html}
</body>
</html>`;
  const blob = new Blob([fullHtml], { type: 'text/html;charset=utf-8' });
  saveAs(blob, `${fileName}.html`);
}

interface ParsedElement {
  type: 'heading' | 'paragraph' | 'list' | 'table' | 'blockquote' | 'code';
  level?: number;
  content?: string;
  items?: string[];
  rows?: string[][];
  listType?: 'bullet' | 'number';
}

function parseHtmlToElements(html: string): ParsedElement[] {
  const temp = document.createElement('div');
  temp.innerHTML = html;
  const elements: ParsedElement[] = [];

  const children = temp.children;
  for (let i = 0; i < children.length; i++) {
    const el = children[i];
    const tagName = el.tagName.toLowerCase();

    if (/^h[1-6]$/.test(tagName)) {
      const level = parseInt(tagName[1]);
      elements.push({
        type: 'heading',
        level,
        content: el.textContent || '',
      });
    } else if (tagName === 'p') {
      elements.push({
        type: 'paragraph',
        content: el.textContent || '',
      });
    } else if (tagName === 'ul' || tagName === 'ol') {
      const items: string[] = [];
      const lis = el.querySelectorAll('li');
      lis.forEach(li => items.push(li.textContent || ''));
      elements.push({
        type: 'list',
        listType: tagName === 'ul' ? 'bullet' : 'number',
        items,
      });
    } else if (tagName === 'table') {
      const rows: string[][] = [];
      const trs = el.querySelectorAll('tr');
      trs.forEach(tr => {
        const cells: string[] = [];
        const tds = tr.querySelectorAll('th, td');
        tds.forEach(td => cells.push(td.textContent || ''));
        rows.push(cells);
      });
      elements.push({ type: 'table', rows });
    } else if (tagName === 'blockquote') {
      elements.push({
        type: 'blockquote',
        content: el.textContent || '',
      });
    } else if (tagName === 'pre') {
      elements.push({
        type: 'code',
        content: el.textContent || '',
      });
    } else if (el.textContent?.trim()) {
      elements.push({
        type: 'paragraph',
        content: el.textContent || '',
      });
    }
  }

  return elements;
}

function getHeadingLevel(level: number): (typeof HeadingLevel)[keyof typeof HeadingLevel] {
  const levels: Record<number, (typeof HeadingLevel)[keyof typeof HeadingLevel]> = {
    1: HeadingLevel.HEADING_1,
    2: HeadingLevel.HEADING_2,
    3: HeadingLevel.HEADING_3,
    4: HeadingLevel.HEADING_4,
    5: HeadingLevel.HEADING_5,
    6: HeadingLevel.HEADING_6,
  };
  return levels[level] || HeadingLevel.HEADING_1;
}

async function exportAsDocx(html: string, fileName: string): Promise<void> {
  const elements = parseHtmlToElements(html);
  const children: (Paragraph | Table)[] = [];

  elements.forEach((el) => {
    switch (el.type) {
      case 'heading':
        children.push(
          new Paragraph({
            text: el.content || '',
            heading: getHeadingLevel(el.level || 1),
          })
        );
        break;
      case 'paragraph':
        children.push(
          new Paragraph({
            children: [new TextRun(el.content || '')],
          })
        );
        break;
      case 'list':
        el.items?.forEach((item, i) => {
          children.push(
            new Paragraph({
              children: [new TextRun(el.listType === 'number' ? `${i + 1}. ${item}` : `- ${item}`)],
              indent: { left: 720 },
            })
          );
        });
        break;
      case 'table':
        if (el.rows && el.rows.length > 0) {
          const table = new Table({
            width: { size: 100, type: WidthType.PERCENTAGE },
            rows: el.rows.map((row, rowIdx) =>
              new TableRow({
                children: row.map(cell =>
                  new TableCell({
                    children: [new Paragraph({
                      children: [new TextRun({
                        text: cell,
                        bold: rowIdx === 0,
                      })],
                    })],
                  })
                ),
              })
            ),
          });
          children.push(table);
        }
        break;
      case 'blockquote':
        children.push(
          new Paragraph({
            children: [new TextRun({
              text: el.content || '',
              italics: true,
            })],
            indent: { left: 720 },
          })
        );
        break;
      case 'code':
        children.push(
          new Paragraph({
            children: [new TextRun({
              text: el.content || '',
              font: 'Consolas',
              size: 20,
            })],
            shading: { fill: 'F5F5F5' },
          })
        );
        break;
    }
  });

  if (children.length === 0) {
    children.push(new Paragraph({ text: '' }));
  }

  const doc = new Document({
    sections: [{
      properties: {},
      children,
    }],
  });

  const blob = await Packer.toBlob(doc);
  saveAs(blob, `${fileName}.docx`);
}

export function getAcceptedFileTypes(): string {
  return '.txt,.md,.markdown,.docx,.doc,.html,.htm';
}
