document.addEventListener('click', function (e) {
  function copyToClipboard(text, btn, successText, defaultText) {
    const copyPromise = (navigator.clipboard && navigator.clipboard.writeText)
      ? navigator.clipboard.writeText(text)
      : new Promise((resolve, reject) => {
          const ta = document.createElement('textarea');
          ta.value = text;
          ta.style.position = 'fixed';
          ta.style.opacity = '0';
          document.body.appendChild(ta);
          ta.select();
          document.execCommand('copy') ? resolve() : reject();
          document.body.removeChild(ta);
        });

    copyPromise.then(() => {
      btn.innerText = successText;
      btn.classList.add('copied');
      setTimeout(() => {
        btn.innerText = defaultText;
        btn.classList.remove('copied');
      }, 1300);
    }).catch(err => console.error('Copy failed:', err));
  }

  // 1. معالجة نقرة زر الكود المضمن
  const inlineBtn = e.target.closest('.inline-code-copy-btn');
  if (inlineBtn) {
    e.preventDefault();
    e.stopPropagation();
    const wrapper = inlineBtn.closest('.inline-code-wrapper');
    const code = wrapper ? wrapper.querySelector('code') : null;
    if (code) {
      copyToClipboard(code.innerText || code.textContent, inlineBtn, '✓', '⧉');
    }
    return;
  }

  // 2. معالجة نقرة زر كتلة الكود الكبيرة
  const blockBtn = e.target.closest('.code-copy-btn');
  if (blockBtn) {
    e.preventDefault();
    e.stopPropagation();
    const pre = blockBtn.closest('pre');
    if (pre) {
      const code = pre.querySelector('code');
      let text = '';
      if (code) {
        text = code.innerText || code.textContent;
      } else {
        const clone = pre.cloneNode(true);
        const btnInClone = clone.querySelector('.code-copy-btn');
        if (btnInClone) btnInClone.remove();
        text = clone.innerText || clone.textContent;
      }
      copyToClipboard(text.trim(), blockBtn, 'Copied! ✓', 'Copy ⧉');
    }
    return;
  }
});