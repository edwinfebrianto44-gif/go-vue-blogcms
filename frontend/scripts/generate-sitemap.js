import fs from 'fs'
import path from 'path'
import { getAllPosts, getAllCategories } from '../src/utils/ssg-routes.js'

const SITE_URL = process.env.VITE_SITE_URL || 'https://blogcms.example.com'
const DIST_PATH = path.join(process.cwd(), 'dist')

// Sitemap priorities and change frequencies
const PAGE_CONFIG = {
  home: { priority: 1.0, changefreq: 'daily' },
  posts: { priority: 0.9, changefreq: 'weekly' },
  postDetail: { priority: 0.8, changefreq: 'monthly' },
  categories: { priority: 0.7, changefreq: 'weekly' },
  categoryDetail: { priority: 0.6, changefreq: 'weekly' },
  static: { priority: 0.5, changefreq: 'monthly' }
}

function formatDate(date) {
  return new Date(date).toISOString().split('T')[0]
}

function createSitemapEntry(url, lastmod = null, changefreq = 'monthly', priority = 0.5) {
  return `  <url>
    <loc>${SITE_URL}${url}</loc>
    ${lastmod ? `<lastmod>${formatDate(lastmod)}</lastmod>` : ''}
    <changefreq>${changefreq}</changefreq>
    <priority>${priority}</priority>
  </url>`
}

async function generateSitemap() {
  console.log('🔄 Generating sitemap.xml...')
  
  try {
    const sitemapEntries = []
    
    // Homepage
    sitemapEntries.push(createSitemapEntry(
      '/',
      new Date(),
      PAGE_CONFIG.home.changefreq,
      PAGE_CONFIG.home.priority
    ))
    
    // Static pages
    const staticPages = [
      '/posts',
      '/about',
      '/contact',
      '/privacy',
      '/terms'
    ]
    
    staticPages.forEach(page => {
      sitemapEntries.push(createSitemapEntry(
        page,
        null,
        PAGE_CONFIG.static.changefreq,
        PAGE_CONFIG.static.priority
      ))
    })
    
    // Fetch and add posts
    const posts = await getAllPosts()
    console.log(`📄 Adding ${posts.length} posts to sitemap...`)
    
    posts.forEach(post => {
      sitemapEntries.push(createSitemapEntry(
        `/posts/${post.slug}`,
        post.updated_at || post.created_at,
        PAGE_CONFIG.postDetail.changefreq,
        PAGE_CONFIG.postDetail.priority
      ))
    })
    
    // Fetch and add categories
    const categories = await getAllCategories()
    console.log(`📂 Adding ${categories.length} categories to sitemap...`)
    
    categories.forEach(category => {
      sitemapEntries.push(createSitemapEntry(
        `/categories/${category.slug}`,
        category.updated_at || category.created_at,
        PAGE_CONFIG.categoryDetail.changefreq,
        PAGE_CONFIG.categoryDetail.priority
      ))
    })
    
    // Create complete sitemap XML
    const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${sitemapEntries.join('\n')}
</urlset>`
    
    // Ensure dist directory exists
    if (!fs.existsSync(DIST_PATH)) {
      fs.mkdirSync(DIST_PATH, { recursive: true })
    }
    
    // Write sitemap file
    const sitemapPath = path.join(DIST_PATH, 'sitemap.xml')
    fs.writeFileSync(sitemapPath, sitemap)
    
    console.log(`✅ Sitemap generated successfully!`)
    console.log(`   📍 Location: ${sitemapPath}`)
    console.log(`   📊 Total URLs: ${sitemapEntries.length}`)
    
    // Also create a sitemap index if we have many URLs
    if (sitemapEntries.length > 1000) {
      await createSitemapIndex()
    }
    
  } catch (error) {
    console.error('❌ Error generating sitemap:', error)
    process.exit(1)
  }
}

async function createSitemapIndex() {
  // For very large sites, create a sitemap index
  // This is a placeholder for when you have multiple sitemaps
  const sitemapIndex = `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap>
    <loc>${SITE_URL}/sitemap.xml</loc>
    <lastmod>${formatDate(new Date())}</lastmod>
  </sitemap>
</sitemapindex>`
  
  const indexPath = path.join(DIST_PATH, 'sitemap-index.xml')
  fs.writeFileSync(indexPath, sitemapIndex)
  console.log(`✅ Sitemap index created: ${indexPath}`)
}

// Also create robots.txt
function generateRobotsTxt() {
  console.log('🤖 Generating robots.txt...')
  
  const robotsTxt = `User-agent: *
Allow: /

# Disallow admin and private areas
Disallow: /dashboard/
Disallow: /admin/
Disallow: /api/
Disallow: /login
Disallow: /register

# Allow specific bots
User-agent: Googlebot
Allow: /

User-agent: Bingbot
Allow: /

# Sitemap location
Sitemap: ${SITE_URL}/sitemap.xml

# Crawl-delay for politeness
Crawl-delay: 1`
  
  const robotsPath = path.join(DIST_PATH, 'robots.txt')
  fs.writeFileSync(robotsPath, robotsTxt)
  
  console.log(`✅ robots.txt generated: ${robotsPath}`)
}

// Run generation
async function main() {
  console.log('🚀 Starting SEO files generation...')
  console.log(`🌐 Site URL: ${SITE_URL}`)
  
  try {
    await generateSitemap()
    generateRobotsTxt()
    
    console.log('🎉 All SEO files generated successfully!')
  } catch (error) {
    console.error('💥 Generation failed:', error)
    process.exit(1)
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main()
}

export { generateSitemap, generateRobotsTxt }
