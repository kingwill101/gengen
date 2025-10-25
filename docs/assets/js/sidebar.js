// Enhanced Sidebar Functionality

document.addEventListener('DOMContentLoaded', function() {
    // Generate Table of Contents
    generateTableOfContents();
    
    // Handle active states for TOC on scroll
    handleTOCScrollHighlight();
    
    // Handle mobile sidebar toggle
    handleMobileSidebar();
    
    // Add smooth scrolling
    addSmoothScrolling();
});

/**
 * Generate Table of Contents from page headings
 */
function generateTableOfContents() {
    const tocContainer = document.getElementById('toc');
    if (!tocContainer) return;
    
    const headings = document.querySelectorAll('.main-content-area h2, .main-content-area h3, .main-content-area h4');
    if (headings.length === 0) {
        tocContainer.style.display = 'none';
        return;
    }
    
    const tocList = document.createElement('ul');
    let currentLevel = 2;
    let currentList = tocList;
    const listStack = [tocList];
    
    headings.forEach((heading, index) => {
        const level = parseInt(heading.tagName.charAt(1));
        const id = heading.id || `heading-${index}`;
        const text = heading.textContent.trim();
        
        // Ensure heading has an ID for linking
        if (!heading.id) {
            heading.id = id;
        }
        
        // Create list item
        const listItem = document.createElement('li');
        const link = document.createElement('a');
        link.href = `#${id}`;
        link.textContent = text;
        link.className = 'toc-link';
        
        // Handle nested levels
        if (level > currentLevel) {
            // Going deeper - create nested list
            const nestedList = document.createElement('ul');
            const lastItem = currentList.lastElementChild;
            if (lastItem) {
                lastItem.appendChild(nestedList);
            }
            currentList = nestedList;
            listStack.push(nestedList);
        } else if (level < currentLevel) {
            // Going back up - pop from stack
            while (listStack.length > 1 && level < currentLevel) {
                listStack.pop();
                currentLevel--;
            }
            currentList = listStack[listStack.length - 1];
        }
        
        currentLevel = level;
        listItem.appendChild(link);
        currentList.appendChild(listItem);
    });
    
    tocContainer.appendChild(tocList);
}

/**
 * Highlight active TOC item based on scroll position
 */
function handleTOCScrollHighlight() {
    const tocLinks = document.querySelectorAll('.toc-link');
    if (tocLinks.length === 0) return;
    
    let ticking = false;
    
    function updateActiveLink() {
        const scrollY = window.scrollY;
        const headings = Array.from(document.querySelectorAll('.main-content-area h2, .main-content-area h3, .main-content-area h4'));
        
        let activeHeading = null;
        
        // Find the current active heading
        for (let i = headings.length - 1; i >= 0; i--) {
            const heading = headings[i];
            const rect = heading.getBoundingClientRect();
            
            if (rect.top <= 100) {
                activeHeading = heading;
                break;
            }
        }
        
        // Update active states
        tocLinks.forEach(link => {
            link.classList.remove('active');
            if (activeHeading && link.getAttribute('href') === `#${activeHeading.id}`) {
                link.classList.add('active');
            }
        });
        
        ticking = false;
    }
    
    function onScroll() {
        if (!ticking) {
            requestAnimationFrame(updateActiveLink);
            ticking = true;
        }
    }
    
    window.addEventListener('scroll', onScroll, { passive: true });
    
    // Initial check
    updateActiveLink();
}

/**
 * Handle mobile sidebar toggle
 */
function handleMobileSidebar() {
    // Create mobile toggle button
    const header = document.querySelector('.site-header .container');
    if (!header) return;
    
    const toggleButton = document.createElement('button');
    toggleButton.className = 'sidebar-toggle';
    toggleButton.innerHTML = '☰';
    toggleButton.setAttribute('aria-label', 'Toggle sidebar');
    
    // Insert toggle button
    const headerContent = header.querySelector('.header-content');
    if (headerContent) {
        headerContent.appendChild(toggleButton);
    }
    
    // Toggle functionality
    const sidebar = document.querySelector('.sidebar');
    if (sidebar) {
        toggleButton.addEventListener('click', function() {
            sidebar.classList.toggle('mobile-open');
            document.body.classList.toggle('sidebar-open');
            
            // Update button text
            toggleButton.innerHTML = sidebar.classList.contains('mobile-open') ? '✕' : '☰';
        });
        
        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', function(e) {
            if (window.innerWidth <= 1024 && 
                !sidebar.contains(e.target) && 
                !toggleButton.contains(e.target) &&
                sidebar.classList.contains('mobile-open')) {
                sidebar.classList.remove('mobile-open');
                document.body.classList.remove('sidebar-open');
                toggleButton.innerHTML = '☰';
            }
        });
        
        // Handle resize
        window.addEventListener('resize', function() {
            if (window.innerWidth > 1024) {
                sidebar.classList.remove('mobile-open');
                document.body.classList.remove('sidebar-open');
                toggleButton.innerHTML = '☰';
            }
        });
    }
}

/**
 * Add smooth scrolling to all anchor links
 */
function addSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                e.preventDefault();
                
                const headerHeight = document.querySelector('.site-header')?.offsetHeight || 0;
                const targetPosition = targetElement.offsetTop - headerHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
                
                // Update URL without jumping
                history.pushState(null, null, `#${targetId}`);
            }
        });
    });
}

/**
 * Search functionality for sidebar
 */
function addSidebarSearch() {
    const sidebar = document.querySelector('.sidebar');
    if (!sidebar) return;
    
    const searchContainer = document.createElement('div');
    searchContainer.className = 'sidebar-search';
    searchContainer.innerHTML = `
        <input type="text" placeholder="Search documentation..." class="search-input">
        <div class="search-results"></div>
    `;
    
    // Insert search at the top of sidebar
    const docsNav = sidebar.querySelector('.docs-nav');
    if (docsNav) {
        docsNav.insertBefore(searchContainer, docsNav.firstChild);
    }
    
    const searchInput = searchContainer.querySelector('.search-input');
    const searchResults = searchContainer.querySelector('.search-results');
    const navItems = Array.from(document.querySelectorAll('.nav-link'));
    
    searchInput.addEventListener('input', function() {
        const query = this.value.toLowerCase().trim();
        
        if (query === '') {
            searchResults.innerHTML = '';
            searchResults.style.display = 'none';
            return;
        }
        
        const matches = navItems.filter(item => 
            item.textContent.toLowerCase().includes(query)
        );
        
        if (matches.length === 0) {
            searchResults.innerHTML = '<div class="no-results">No results found</div>';
        } else {
            searchResults.innerHTML = matches
                .slice(0, 5) // Limit to 5 results
                .map(item => `
                    <a href="${item.href}" class="search-result">
                        ${item.textContent}
                    </a>
                `).join('');
        }
        
        searchResults.style.display = 'block';
    });
    
    // Hide results when clicking outside
    document.addEventListener('click', function(e) {
        if (!searchContainer.contains(e.target)) {
            searchResults.style.display = 'none';
        }
    });
}

// Initialize search when DOM is ready
document.addEventListener('DOMContentLoaded', addSidebarSearch);

// Progressive enhancement for keyboard navigation
document.addEventListener('keydown', function(e) {
    // Focus search on Ctrl+K or Cmd+K
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        const searchInput = document.querySelector('.search-input');
        if (searchInput) {
            searchInput.focus();
        }
    }
    
    // Navigate with arrow keys in sidebar
    if (document.activeElement && document.activeElement.closest('.sidebar')) {
        const links = Array.from(document.querySelectorAll('.nav-link, .toc-link'));
        const currentIndex = links.indexOf(document.activeElement);
        
        if (e.key === 'ArrowDown' && currentIndex < links.length - 1) {
            e.preventDefault();
            links[currentIndex + 1].focus();
        } else if (e.key === 'ArrowUp' && currentIndex > 0) {
            e.preventDefault();
            links[currentIndex - 1].focus();
        }
    }
}); 