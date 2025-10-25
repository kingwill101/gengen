// Copy Button Functionality
(function() {
  'use strict';
  
  function addCopyButtons() {
    const codeWrappers = document.querySelectorAll('.code-block-wrapper');
    
    codeWrappers.forEach(function(wrapper) {
      // Skip if copy button already exists
      if (wrapper.querySelector('.copy-button')) return;
      
      const codeBlock = wrapper.querySelector('code');
      if (!codeBlock) return;
      
      // Create copy button
      const copyButton = document.createElement('button');
      copyButton.className = 'copy-button';
      copyButton.textContent = 'Copy';
      copyButton.setAttribute('aria-label', 'Copy code to clipboard');
      
      // Add click handler
      copyButton.addEventListener('click', function() {
        const text = codeBlock.textContent || codeBlock.innerText;
        
        // Use modern clipboard API if available
        if (navigator.clipboard) {
          navigator.clipboard.writeText(text).then(function() {
            showCopySuccess(copyButton);
          }).catch(function() {
            fallbackCopy(text, copyButton);
          });
        } else {
          fallbackCopy(text, copyButton);
        }
      });
      
      wrapper.appendChild(copyButton);
    });
  }
  
  function showCopySuccess(button) {
    button.classList.add('copied');
    button.textContent = 'Copied';
    
    setTimeout(function() {
      button.classList.remove('copied');
      button.textContent = 'Copy';
    }, 2000);
  }
  
  function fallbackCopy(text, button) {
    // Fallback for older browsers
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.opacity = '0';
    document.body.appendChild(textArea);
    textArea.select();
    
    try {
      document.execCommand('copy');
      showCopySuccess(button);
    } catch (err) {
      console.error('Copy failed:', err);
    }
    
    document.body.removeChild(textArea);
  }
  
  // Initialize copy buttons when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addCopyButtons);
  } else {
    addCopyButtons();
  }
  
  // Also run after a short delay to catch dynamically added code blocks
  setTimeout(addCopyButtons, 100);
})(); 