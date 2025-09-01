import { useHead } from '@vueuse/head'
import { computed } from 'vue'

export function useSEO(options = {}) {
  const defaultOptions = {
    title: 'Blog CMS',
    description: 'A modern content management system built with Vue.js and Go',
    image: '/og-image.jpg',
    url: 'https://your-domain.com',
    type: 'website',
    siteName: 'Blog CMS',
    twitterCard: 'summary_large_image',
    twitterSite: '@your_twitter'
  }

  const seoOptions = { ...defaultOptions, ...options }

  const head = useHead({
    title: computed(() => seoOptions.title),
    meta: [
      {
        name: 'description',
        content: computed(() => seoOptions.description)
      },
      {
        name: 'keywords',
        content: computed(() => seoOptions.keywords || '')
      },
      // Open Graph
      {
        property: 'og:type',
        content: computed(() => seoOptions.type)
      },
      {
        property: 'og:title',
        content: computed(() => seoOptions.title)
      },
      {
        property: 'og:description',
        content: computed(() => seoOptions.description)
      },
      {
        property: 'og:image',
        content: computed(() => seoOptions.image)
      },
      {
        property: 'og:url',
        content: computed(() => seoOptions.url)
      },
      {
        property: 'og:site_name',
        content: computed(() => seoOptions.siteName)
      },
      // Twitter Card
      {
        name: 'twitter:card',
        content: computed(() => seoOptions.twitterCard)
      },
      {
        name: 'twitter:site',
        content: computed(() => seoOptions.twitterSite)
      },
      {
        name: 'twitter:title',
        content: computed(() => seoOptions.title)
      },
      {
        name: 'twitter:description',
        content: computed(() => seoOptions.description)
      },
      {
        name: 'twitter:image',
        content: computed(() => seoOptions.image)
      },
      // Additional meta tags
      {
        name: 'robots',
        content: computed(() => seoOptions.robots || 'index,follow')
      },
      {
        name: 'author',
        content: computed(() => seoOptions.author || 'Blog CMS')
      }
    ],
    link: [
      {
        rel: 'canonical',
        href: computed(() => seoOptions.url)
      }
    ]
  })

  return {
    updateSEO: (newOptions) => {
      Object.assign(seoOptions, newOptions)
    },
    seoOptions
  }
}

export function generateStructuredData(type, data) {
  switch (type) {
    case 'article':
      return {
        '@context': 'https://schema.org',
        '@type': 'Article',
        headline: data.title,
        description: data.description,
        image: data.image ? [data.image] : [],
        datePublished: data.publishedAt,
        dateModified: data.updatedAt,
        author: {
          '@type': 'Person',
          name: data.author?.name || 'Anonymous',
          url: data.author?.url
        },
        publisher: {
          '@type': 'Organization',
          name: 'Blog CMS',
          logo: {
            '@type': 'ImageObject',
            url: '/logo.png'
          }
        },
        mainEntityOfPage: {
          '@type': 'WebPage',
          '@id': data.url
        }
      }
    
    case 'website':
      return {
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        name: data.name,
        description: data.description,
        url: data.url,
        potentialAction: {
          '@type': 'SearchAction',
          target: {
            '@type': 'EntryPoint',
            urlTemplate: `${data.url}/posts?q={search_term_string}`
          },
          'query-input': 'required name=search_term_string'
        }
      }
    
    case 'breadcrumb':
      return {
        '@context': 'https://schema.org',
        '@type': 'BreadcrumbList',
        itemListElement: data.items.map((item, index) => ({
          '@type': 'ListItem',
          position: index + 1,
          name: item.name,
          item: item.url
        }))
      }
    
    default:
      return null
  }
}

export function extractTextFromHTML(html, maxLength = 160) {
  // Simple HTML tag removal for meta descriptions
  const text = html
    .replace(/<[^>]*>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
}

export function generateKeywords(text, additionalKeywords = []) {
  // Simple keyword extraction from text
  const words = text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 3)
  
  const wordCount = {}
  words.forEach(word => {
    wordCount[word] = (wordCount[word] || 0) + 1
  })
  
  const topWords = Object.entries(wordCount)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 5)
    .map(([word]) => word)
  
  return [...additionalKeywords, ...topWords].join(', ')
}
