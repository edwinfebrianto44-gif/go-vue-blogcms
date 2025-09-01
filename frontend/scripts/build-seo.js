#!/usr/bin/env node

import { generateSitemap, generateRobotsTxt } from './generate-sitemap.js'
import { generateRssFeed } from './generate-rss.js'

console.log('🏗️  Building SEO assets...')
console.log('=' .repeat(50))

async function buildAll() {
  try {
    // Generate sitemap and robots.txt
    await generateSitemap()
    generateRobotsTxt()
    
    // Generate RSS feeds
    await generateRssFeed()
    
    console.log('=' .repeat(50))
    console.log('🎉 All SEO assets generated successfully!')
    console.log('')
    console.log('Generated files:')
    console.log('  📄 dist/sitemap.xml')
    console.log('  🤖 dist/robots.txt') 
    console.log('  📡 dist/rss.xml')
    console.log('  📋 dist/feed.json')
    console.log('')
    console.log('💡 Add these to your server configuration:')
    console.log('  - Sitemap: https://yourdomain.com/sitemap.xml')
    console.log('  - RSS Feed: https://yourdomain.com/rss.xml')
    console.log('  - JSON Feed: https://yourdomain.com/feed.json')
    
  } catch (error) {
    console.error('💥 Build failed:', error)
    process.exit(1)
  }
}

buildAll()
