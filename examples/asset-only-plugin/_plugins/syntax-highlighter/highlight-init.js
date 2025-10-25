// Syntax Highlighter Plugin - Initialization
(function() {
  'use strict';
  
  console.log('Syntax Highlighter Plugin: JavaScript loaded');
  
  // Enhanced highlighting with line numbers
  function initializeHighlighting() {
    const codeBlocks = document.querySelectorAll('pre code');
    
    codeBlocks.forEach(function(block) {
      // Add line numbers class
      if (!block.classList.contains('hljs-line-numbers')) {
        block.classList.add('hljs-line-numbers');
      }
      
      // Wrap in container for copy button
      if (!block.parentElement.classList.contains('code-block-wrapper')) {
        const wrapper = document.createElement('div');
        wrapper.className = 'code-block-wrapper';
        block.parentElement.parentNode.insertBefore(wrapper, block.parentElement);
        wrapper.appendChild(block.parentElement);
      }
    });
  }
  
  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeHighlighting);
  } else {
    initializeHighlighting();
  }
})(); 