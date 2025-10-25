(() => {
  const sidebarToggle = document.querySelector('.docs-sidebar__toggle');
  const sidebar = document.querySelector('.docs-sidebar');
  if (sidebarToggle && sidebar) {
    sidebarToggle.addEventListener('click', () => {
      sidebar.classList.toggle('is-open');
      document.body.classList.toggle('sidebar-open');
    });
  }

  const tocTarget = document.querySelector('#docs-toc-list');
  if (tocTarget) {
    const headings = document.querySelectorAll('.docs-article__body h2, .docs-article__body h3');
    if (headings.length) {
      const list = document.createElement('ul');
      headings.forEach((heading) => {
        const id = heading.id || heading.textContent.trim().toLowerCase().replace(/\s+/g, '-');
        heading.id = id;
        const item = document.createElement('li');
        const link = document.createElement('a');
        link.href = `#${id}`;
        link.textContent = heading.textContent;
        item.appendChild(link);
        list.appendChild(item);
      });
      tocTarget.appendChild(list);
    } else {
      tocTarget.innerHTML = '<p class="toc-empty">No headings on this page</p>';
    }
  }
})();
