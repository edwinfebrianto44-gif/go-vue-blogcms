import { ref, computed } from 'vue'

// Global loading state management
const globalLoadingState = ref(new Map())
const globalProgress = ref(new Map())

export function useLoading(key = 'default') {
  // Individual loading state for this key
  const isLoading = computed({
    get: () => globalLoadingState.value.get(key) || false,
    set: (value) => {
      const newState = new Map(globalLoadingState.value)
      if (value) {
        newState.set(key, true)
      } else {
        newState.delete(key)
      }
      globalLoadingState.value = newState
    }
  })

  // Progress for this key
  const progress = computed({
    get: () => globalProgress.value.get(key) || 0,
    set: (value) => {
      const newProgress = new Map(globalProgress.value)
      newProgress.set(key, Math.min(Math.max(value, 0), 100))
      globalProgress.value = newProgress
    }
  })

  // Check if any loading is active
  const hasAnyLoading = computed(() => globalLoadingState.value.size > 0)

  // Start loading with optional message
  const startLoading = (message = 'Loading...') => {
    isLoading.value = true
    return {
      updateProgress: (value) => { progress.value = value },
      updateMessage: (msg) => { /* Could extend to support messages */ },
      finish: () => { stopLoading() }
    }
  }

  // Stop loading
  const stopLoading = () => {
    isLoading.value = false
    progress.value = 0
  }

  // Async wrapper that automatically manages loading state
  const withLoading = async (asyncFn, options = {}) => {
    const { 
      errorHandler = console.error,
      finallyHandler = null,
      progressCallback = null 
    } = options

    try {
      const loader = startLoading()
      
      if (progressCallback) {
        progressCallback((value) => loader.updateProgress(value))
      }

      const result = await asyncFn()
      return result
    } catch (error) {
      errorHandler(error)
      throw error
    } finally {
      stopLoading()
      if (finallyHandler) {
        finallyHandler()
      }
    }
  }

  // Promise-based loading with timeout
  const withTimeout = async (asyncFn, timeout = 30000) => {
    return Promise.race([
      withLoading(asyncFn),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Operation timeout')), timeout)
      )
    ])
  }

  return {
    isLoading,
    progress,
    hasAnyLoading,
    startLoading,
    stopLoading,
    withLoading,
    withTimeout
  }
}

// Specialized hooks for common use cases
export function useApiLoading() {
  return useLoading('api')
}

export function usePageLoading() {
  return useLoading('page')
}

export function useImageLoading() {
  return useLoading('image')
}

// Loading state for route transitions
export function useRouteLoading() {
  const routeLoading = useLoading('route')
  
  const startRouteTransition = () => {
    routeLoading.startLoading('Navigating...')
  }
  
  const endRouteTransition = () => {
    // Add a small delay to avoid flash
    setTimeout(() => {
      routeLoading.stopLoading()
    }, 100)
  }
  
  return {
    ...routeLoading,
    startRouteTransition,
    endRouteTransition
  }
}

// Batch loading operations
export function useBatchLoading() {
  const batchKey = `batch-${Date.now()}`
  const batchLoading = useLoading(batchKey)
  
  const runBatch = async (operations) => {
    const total = operations.length
    let completed = 0
    
    batchLoading.startLoading('Processing...')
    
    try {
      const results = []
      
      for (const operation of operations) {
        try {
          const result = await operation()
          results.push({ success: true, data: result })
        } catch (error) {
          results.push({ success: false, error })
        }
        
        completed++
        batchLoading.progress.value = (completed / total) * 100
      }
      
      return results
    } finally {
      batchLoading.stopLoading()
    }
  }
  
  return {
    ...batchLoading,
    runBatch
  }
}

// Image loading with preloading support
export function useImagePreloader() {
  const imageLoading = useLoading('images')
  
  const preloadImage = (src) => {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = () => resolve(img)
      img.onerror = reject
      img.src = src
    })
  }
  
  const preloadImages = async (srcs) => {
    const total = srcs.length
    let loaded = 0
    
    imageLoading.startLoading('Loading images...')
    
    try {
      const promises = srcs.map(async (src) => {
        try {
          const img = await preloadImage(src)
          loaded++
          imageLoading.progress.value = (loaded / total) * 100
          return { src, success: true, img }
        } catch (error) {
          loaded++
          imageLoading.progress.value = (loaded / total) * 100
          return { src, success: false, error }
        }
      })
      
      const results = await Promise.all(promises)
      return results
    } finally {
      imageLoading.stopLoading()
    }
  }
  
  return {
    ...imageLoading,
    preloadImage,
    preloadImages
  }
}

// Development helper
export function useLoadingDebug() {
  if (process.env.NODE_ENV !== 'development') {
    return { logLoadingState: () => {} }
  }
  
  const logLoadingState = () => {
    console.group('🔄 Loading States')
    console.log('Active:', Object.fromEntries(globalLoadingState.value))
    console.log('Progress:', Object.fromEntries(globalProgress.value))
    console.groupEnd()
  }
  
  return { logLoadingState }
}
