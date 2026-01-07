// GenGen Documentation Site JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Mobile navigation toggle (if needed in the future)
    const mobileToggle = document.querySelector('.mobile-toggle');
    const mainNav = document.querySelector('.main-nav');
    
    if (mobileToggle && mainNav) {
        mobileToggle.addEventListener('click', function() {
            mainNav.classList.toggle('active');
        });
    }
    
    // Smooth scrolling for anchor links
    const anchorLinks = document.querySelectorAll('a[href^="#"]');
    anchorLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                e.preventDefault();
                const headerHeight = document.querySelector('.site-header').offsetHeight;
                const targetPosition = target.offsetTop - headerHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Copy code button functionality
    const codeBlocks = document.querySelectorAll('pre code');
    codeBlocks.forEach(codeBlock => {
        const pre = codeBlock.parentNode;
        const button = document.createElement('button');
        button.className = 'copy-code-btn';
        button.textContent = 'Copy';
        button.addEventListener('click', function() {
            navigator.clipboard.writeText(codeBlock.textContent).then(() => {
                button.textContent = 'Copied!';
                setTimeout(() => {
                    button.textContent = 'Copy';
                }, 2000);
            });
        });
        pre.appendChild(button);
    });
    
    // Highlight current section in navigation
    const sections = document.querySelectorAll('h2, h3');
    const navLinks = document.querySelectorAll('.docs-nav a');
    
    function highlightCurrentSection() {
        let currentSection = null;
        const scrollPosition = window.scrollY + 100;
        
        sections.forEach(section => {
            if (section.offsetTop <= scrollPosition) {
                currentSection = section;
            }
        });
        
        if (currentSection) {
            const currentId = currentSection.id;
            navLinks.forEach(link => {
                link.classList.remove('current');
                if (link.getAttribute('href') === `#${currentId}`) {
                    link.classList.add('current');
                }
            });
        }
    }
    
    // Throttled scroll handler
    let ticking = false;
    function handleScroll() {
        if (!ticking) {
            requestAnimationFrame(() => {
                highlightCurrentSection();
                ticking = false;
            });
            ticking = true;
        }
    }
    
    window.addEventListener('scroll', handleScroll);
    
    // Search functionality (basic implementation)
    const searchInput = document.querySelector('.search-input');
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            const query = this.value.toLowerCase();
            const searchResults = document.querySelector('.search-results');
            
            if (query.length > 2) {
                // Simple search implementation
                // In a real implementation, you'd want to use a proper search index
                const content = document.querySelector('.main-content-area').textContent.toLowerCase();
                if (content.includes(query)) {
                    searchResults.innerHTML = '<div class="search-result">Found matches in current page</div>';
                    searchResults.style.display = 'block';
                } else {
                    searchResults.innerHTML = '<div class="search-result">No results found</div>';
                    searchResults.style.display = 'block';
                }
            } else {
                searchResults.style.display = 'none';
            }
        });
    }
    
    console.log('GenGen Documentation site loaded successfully!');
}); 