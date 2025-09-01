import fs from 'fs'
import path from 'path'
import { getAllPosts } from '../src/utils/ssg-routes.js'

const SITE_URL = process.env.VITE_SITE_URL || 'https://blogcms.example.com'
const SITE_NAME = 'Blog CMS'
const SITE_DESCRIPTION = 'Latest articles and insights from our blog'
const SITE_LANGUAGE = 'en-us'
const DIST_PATH = path.join(process.cwd(), 'dist')

function escapeXml(str) {
  if (!str) return ''
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function formatRssDate(date) {
  return new Date(date).toUTCString()
}

function truncateDescription(content, maxLength = 300) {
  if (!content) return ''
  
  // Strip HTML tags
  const textOnly = content.replace(/<[^>]*>/g, '')
  
  if (textOnly.length <= maxLength) {
    return textOnly
  }
  
  return textOnly.substring(0, maxLength).trim() + '...'
}

async function generateRssFeed() {
  console.log('📡 Generating RSS 2.0 feed...')
  
  try {
    // Fetch latest posts (limit to 50 for RSS)
    const allPosts = await getAllPosts()
    const latestPosts = allPosts
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 50)
    
    console.log(`📄 Adding ${latestPosts.length} latest posts to RSS feed...`)
    
    const buildDate = formatRssDate(new Date())
    const lastBuildDate = latestPosts.length > 0 
      ? formatRssDate(latestPosts[0].created_at)
      : buildDate
    
    // Create RSS items
    const rssItems = latestPosts.map(post => {
      const postUrl = `${SITE_URL}/posts/${post.slug}`
      const pubDate = formatRssDate(post.created_at)
      const description = truncateDescription(post.content)
      const categoryName = post.category?.name || 'Uncategorized'
      
      return `    <item>
      <title>${escapeXml(post.title)}</title>
      <description>${escapeXml(description)}</description>
      <link>${postUrl}</link>
      <guid isPermaLink="true">${postUrl}</guid>
      <pubDate>${pubDate}</pubDate>
      <category>${escapeXml(categoryName)}</category>
      ${post.author ? `<author>noreply@example.com (${escapeXml(post.author)})</author>` : ''}
      ${post.featured_image ? `<enclosure url="${escapeXml(post.featured_image)}" type="image/jpeg" />` : ''}
    </item>`
    }).join('\n')
    
    // Create complete RSS feed
    const rssFeed = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${escapeXml(SITE_NAME)}</title>
    <description>${escapeXml(SITE_DESCRIPTION)}</description>
    <link>${SITE_URL}</link>
    <atom:link href="${SITE_URL}/rss.xml" rel="self" type="application/rss+xml" />
    <language>${SITE_LANGUAGE}</language>
    <lastBuildDate>${lastBuildDate}</lastBuildDate>
    <pubDate>${buildDate}</pubDate>
    <ttl>60</ttl>
    <generator>Blog CMS RSS Generator</generator>
    <managingEditor>noreply@example.com (${SITE_NAME})</managingEditor>
    <webMaster>noreply@example.com (${SITE_NAME})</webMaster>
    <image>
      <url>${SITE_URL}/favicon.ico</url>
      <title>${escapeXml(SITE_NAME)}</title>
      <link>${SITE_URL}</link>
      <width>32</width>
      <height>32</height>
    </image>
${rssItems}
  </channel>
</rss>`
    
    // Ensure dist directory exists
    if (!fs.existsSync(DIST_PATH)) {
      fs.mkdirSync(DIST_PATH, { recursive: true })
    }
    
    // Write RSS feed file
    const rssPath = path.join(DIST_PATH, 'rss.xml')
    fs.writeFileSync(rssPath, rssFeed)
    
    console.log(`✅ RSS feed generated successfully!`)
    console.log(`   📍 Location: ${rssPath}`)
    console.log(`   📊 Total items: ${latestPosts.length}`)
    
    // Also generate a JSON feed for modern applications
    await generateJsonFeed(latestPosts)
    
  } catch (error) {
    console.error('❌ Error generating RSS feed:', error)
    process.exit(1)
  }
}

async function generateJsonFeed(posts) {
  console.log('📋 Generating JSON Feed...')
  
  const jsonFeed = {
    version: "https://jsonfeed.org/version/1.1",
    title: SITE_NAME,
    description: SITE_DESCRIPTION,
    home_page_url: SITE_URL,
    feed_url: `${SITE_URL}/feed.json`,
    language: SITE_LANGUAGE,
    favicon: `${SITE_URL}/favicon.ico`,
    items: posts.map(post => ({
      id: `${SITE_URL}/posts/${post.slug}`,
      title: post.title,
      content_html: post.content,
      summary: truncateDescription(post.content),
      url: `${SITE_URL}/posts/${post.slug}`,
      date_published: new Date(post.created_at).toISOString(),
      date_modified: post.updated_at ? new Date(post.updated_at).toISOString() : undefined,
      author: post.author ? { name: post.author } : undefined,
      tags: post.category ? [post.category.name] : undefined,
      image: post.featured_image || undefined
    }))
  }
  
  const jsonPath = path.join(DIST_PATH, 'feed.json')
  fs.writeFileSync(jsonPath, JSON.stringify(jsonFeed, null, 2))
  
  console.log(`✅ JSON Feed generated: ${jsonPath}`)
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  generateRssFeed()
}

export { generateRssFeed }
