({
  onWillParseMarkdown: async function (markdown) {
    return markdown;
  },

  onDidParseMarkdown: async function (html) {
    // 1. عزل كتل الأكواد الكبيرة <pre>...</pre> مؤقتاً
    const preBlocks = [];
    html = html.replace(/<pre[\s\S]*?<\/pre>/gi, function (match) {
      preBlocks.push(match);
      return `___PRE_BLOCK_${preBlocks.length - 1}___`;
    });

    // 2. توليد زر النسخ لجميع الأكواد المضمنة (`code`)
    html = html.replace(/<code([^>]*)>([\s\S]*?)<\/code>/gi, function (match, attrs, content) {
      return `<span class="inline-code-wrapper"><code${attrs}>${content}</code><button class="inline-code-copy-btn" title="نسخ">⧉</button></span>`;
    });

    // 3. إعادة كتل <pre> مع إضافة زر النسخ الخاص بها
    html = html.replace(/___PRE_BLOCK_(\d+)___/g, function (match, index) {
      const pre = preBlocks[index];
      return pre.replace(/<pre([^>]*)>/i, '<pre$1><button class="code-copy-btn" title="نسخ الكود">Copy ⧉</button>');
    });

    return html;
  },
});