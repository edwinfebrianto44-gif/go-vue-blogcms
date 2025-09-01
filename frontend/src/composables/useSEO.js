import { useHead } from '@vueuse/head'

export function useSEO({
  title,
  description,
  image,
  url,
  type = 'website',
  author,
  publishedTime,
  modifiedTime,
  tags = [],
  canonical
} = {}) {
  const SITE_NAME = 'Blog CMS'
  const SITE_URL = import.meta.env.VITE_SITE_URL || 'https://blogcms.example.com'
  
  const fullTitle = title ? `${title} | ${SITE_NAME}` : SITE_NAME
  const fullDescription = description || 'Latest articles and insights from our blog'
  const fullUrl = url ? `${SITE_URL}${url}` : SITE_URL
  const fullImage = image || `${SITE_URL}/og-default.jpg`
  const canonicalUrl = canonical || fullUrl
  
  const headConfig = {
    title: fullTitle,
    meta: [
      // Basic meta tags
      { name: 'description', content: fullDescription },
      { name: 'keywords', content: tags.join(', ') },
      { name: 'author', content: author || SITE_NAME },
      
      // Open Graph meta tags
      { property: 'og:title', content: fullTitle },
      { property: 'og:description', content: fullDescription },
      { property: 'og:image', content: fullImage },
      { property: 'og:url', content: fullUrl },
      { property: 'og:type', content: type },
      { property: 'og:site_name', content: SITE_NAME },
      { property: 'og:locale', content: 'en_US' },
      
      // Twitter Card meta tags
      { name: 'twitter:card', content: 'summary_large_image' },
      { name: 'twitter:title', content: fullTitle },
      { name: 'twitter:description', content: fullDescription },
      { name: 'twitter:image', content: fullImage },
      { name: 'twitter:site', content: '@blogcms' },
      { name: 'twitter:creator', content: author ? `@${author}` : '@blogcms' },
      
      // Article specific meta tags
      ...(type === 'article' && publishedTime ? [
        { property: 'article:published_time', content: new Date(publishedTime).toISOString() }
      ] : []),
      ...(type === 'article' && modifiedTime ? [
        { property: 'article:modified_time', content: new Date(modifiedTime).toISOString() }
      ] : []),
      ...(type === 'article' && author ? [
        { property: 'article:author', content: author }
      ] : []),
      ...(type === 'article' && tags.length > 0 ? 
        tags.map(tag => ({ property: 'article:tag', content: tag })) : []
      ),
      
      // Additional SEO meta tags
      { name: 'robots', content: 'index, follow' },
      { name: 'googlebot', content: 'index, follow' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { name: 'theme-color', content: '#3b82f6' },
      { name: 'msapplication-TileColor', content: '#3b82f6' }
    ],
    link: [
      // Canonical URL
      { rel: 'canonical', href: canonicalUrl },
      
      // RSS and JSON feeds
      { rel: 'alternate', type: 'application/rss+xml', title: `${SITE_NAME} RSS`, href: `${SITE_URL}/rss.xml` },
      { rel: 'alternate', type: 'application/feed+json', title: `${SITE_NAME} JSON Feed`, href: `${SITE_URL}/feed.json` },
      
      // Preconnect to external domains for performance
      { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
      { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' }
    ]
  }
  
  useHead(headConfig)
  
  return {
    title: fullTitle,
    description: fullDescription,
    url: fullUrl,
    image: fullImage,
    canonical: canonicalUrl
  }
}

export function createJsonLd(data) {
  return {
    tag: 'script',
    type: 'application/ld+json',
    innerHTML: JSON.stringify(data, null, 2)
  }
}

export function createBreadcrumbJsonLd(items) {
  const SITE_URL = import.meta.env.VITE_SITE_URL || 'https://blogcms.example.com'
  
  return createJsonLd({
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: `${SITE_URL}${item.url}`
    }))
  })
}

export function createOrganizationJsonLd() {
  const SITE_URL = import.meta.env.VITE_SITE_URL || 'https://blogcms.example.com'
  
  return createJsonLd({
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: 'Blog CMS',
    url: SITE_URL,
    logo: `${SITE_URL}/logo.png`,
    sameAs: [
      'https://twitter.com/blogcms',
      'https://facebook.com/blogcms',
      'https://linkedin.com/company/blogcms'
    ],
    contactPoint: {
      '@type': 'ContactPoint',
      telephone: '+1-555-123-4567',
      contactType: 'Customer Service',
      availableLanguage: ['English']
    }
  })
}

export function createWebsiteJsonLd() {
  const SITE_URL = import.meta.env.VITE_SITE_URL || 'https://blogcms.example.com'
  
  return createJsonLd({
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'Blog CMS',
    url: SITE_URL,
    description: 'Latest articles and insights from our blog',
    potentialAction: {
      '@type': 'SearchAction',
      target: {
        '@type': 'EntryPoint',
        urlTemplate: `${SITE_URL}/search?q={search_term_string}`
      },
      'query-input': 'required name=search_term_string'
    },
    publisher: {
      '@type': 'Organization',
      name: 'Blog CMS',
      url: SITE_URL
    }
  })
}
