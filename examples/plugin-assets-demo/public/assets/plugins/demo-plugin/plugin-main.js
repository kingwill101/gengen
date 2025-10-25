// Demo Plugin JavaScript
(function() {
  'use strict';
  
  console.log('Demo Plugin: JavaScript file loaded');
  
  // Add a demo banner to the page
  function addDemoBanner() {
    const banner = document.createElement('div');
    banner.className = 'demo-plugin-banner';
    banner.innerHTML = '🚀 Demo Plugin Active - Asset Injection Working!';
    
    const body = document.body;
    if (body.firstChild) {
      body.insertBefore(banner, body.firstChild);
    } else {
      body.appendChild(banner);
    }
  }
  
  // Add interactive elements
  function addInteractiveElements() {
    const highlights = document.querySelectorAll('.demo-plugin-highlight');
    highlights.forEach(function(highlight) {
      const button = document.createElement('button');
      button.className = 'demo-plugin-button';
      button.textContent = 'Click me!';
      button.addEventListener('click', function() {
        alert('Demo Plugin button clicked!');
      });
      highlight.appendChild(button);
    });
  }
  
  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      addDemoBanner();
      addInteractiveElements();
    });
  } else {
    addDemoBanner();
    addInteractiveElements();
  }
})(); 