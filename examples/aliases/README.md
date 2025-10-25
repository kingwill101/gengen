# GenGen Aliases Example

This example demonstrates how to use **aliases** in GenGen to create multiple URLs that point to the same content.

## What This Example Shows

This site contains four pages that showcase different real-world alias scenarios:

### 1. Homepage (`index.md`)
**Scenario**: Multiple entry points
- **Main URL**: `/`
- **Aliases**: `home.html`, `welcome.html`, `start.html`
- **Use case**: Providing multiple intuitive entry points to your site

### 2. About Page (`about.md`)
**Scenario**: Company rebranding
- **Main URL**: `/about/`
- **Aliases**: `oldtech-inc.html`, `old-company.html`, `company-info.html`, etc.
- **Use case**: Maintaining SEO and links after company rebranding

### 3. Blog Post (`_posts/2024-01-15-getting-started.md`)
**Scenario**: Platform migration
- **Main URL**: `/posts/getting-started/`
- **Aliases**: Jekyll-style URLs, WordPress URLs, tutorial URLs
- **Use case**: Preserving URLs when migrating from other platforms

### 4. Contact Page (`contact.md`)
**Scenario**: Multiple user mental models
- **Main URL**: `/contact/`
- **Aliases**: `contact-us.html`, `get-in-touch.html`, `support.html`, etc.
- **Use case**: Accommodating different ways users think about contact information

## How to Use This Example

### 1. Build the Site

```bash
cd examples/aliases_example
gengen build
```

### 2. Explore the Generated Files

After building, check the `public/` directory. You'll see:

```
public/
├── index.html                    # Main homepage
├── home.html                     # Alias copy
├── welcome.html                  # Alias copy
├── start.html                    # Alias copy
├── about/
│   └── index.html               # Main about page
├── oldtech-inc.html             # Alias copy
├── old-company.html             # Alias copy
├── company-info.html            # Alias copy
├── posts/
│   └── getting-started/
│       └── index.html           # Main blog post
├── 2024/01/15/getting-started-with-gengen.html  # Alias copy
├── blog/gengen-tutorial.html    # Alias copy
├── contact/
│   └── index.html               # Main contact page
├── contact-us.html              # Alias copy
├── get-in-touch.html            # Alias copy
├── support.html                 # Alias copy
└── hello.html                   # Alias copy
```

### 3. Test the Aliases

If you serve the site locally, you can test that all aliases work:

```bash
# All these URLs show the same homepage content:
http://localhost:3000/
http://localhost:3000/home.html
http://localhost:3000/welcome.html
http://localhost:3000/start.html

# All these URLs show the same about page:
http://localhost:3000/about/
http://localhost:3000/oldtech-inc.html
http://localhost:3000/old-company.html

# And so on for all the aliases...
```

## Key Features Demonstrated

### 1. Visual Alias Display
The layout template includes a special section that shows all aliases for each page, making it easy to see which alternative URLs are available.

### 2. Different Alias Formats
- **Array format**: `aliases: [alias1.html, alias2.html]`
- **YAML list format**: 
  ```yaml
  aliases:
    - alias1.html
    - alias2.html
  ```

### 3. Path Types
- **Relative paths**: `home.html`
- **Directory paths**: `blog/tutorial.html`
- **Absolute paths**: `/2024/01/15/post.html`

### 4. Real-World Scenarios
Each page represents a common use case where aliases provide real value:
- Homepage: Multiple entry points
- About: Company rebranding
- Blog: Platform migration  
- Contact: User experience optimization

## Learning Points

1. **Aliases create identical copies** - Not redirects, but full content copies
2. **File extensions are preserved** - GenGen automatically handles extensions
3. **Directory structure is created** - Subdirectories are created as needed
4. **SEO friendly** - Each alias is a real page with full content
5. **Backward compatibility** - Perfect for migrations and restructuring

## Try It Yourself

1. Modify the aliases in any of the files
2. Rebuild the site with `gengen build`
3. Check the `public/` directory to see the new alias files
4. Test the URLs to confirm they work

This example provides a practical foundation for understanding and implementing aliases in your own GenGen sites! 