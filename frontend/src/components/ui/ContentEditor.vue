<template>
  <div class="border border-secondary-300 rounded-lg overflow-hidden">
    <!-- Editor Toolbar -->
    <div class="bg-secondary-50 border-b border-secondary-200 px-4 py-2">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <!-- Format Toggle -->
          <div class="flex rounded-md overflow-hidden">
            <button
              @click="isMarkdown = true"
              :class="[
                'px-3 py-1 text-sm font-medium border',
                isMarkdown
                  ? 'bg-primary-600 text-white border-primary-600'
                  : 'bg-white text-secondary-700 border-secondary-300 hover:bg-secondary-50'
              ]"
            >
              Markdown
            </button>
            <button
              @click="isMarkdown = false"
              :class="[
                'px-3 py-1 text-sm font-medium border-l-0 border',
                !isMarkdown
                  ? 'bg-primary-600 text-white border-primary-600'
                  : 'bg-white text-secondary-700 border-secondary-300 hover:bg-secondary-50'
              ]"
            >
              Rich Text
            </button>
          </div>

          <!-- View Toggle -->
          <div class="flex rounded-md overflow-hidden ml-4">
            <button
              @click="showPreview = false"
              :class="[
                'px-3 py-1 text-sm font-medium border',
                !showPreview
                  ? 'bg-secondary-700 text-white border-secondary-700'
                  : 'bg-white text-secondary-700 border-secondary-300 hover:bg-secondary-50'
              ]"
            >
              <PencilIcon class="h-4 w-4 mr-1 inline" />
              Edit
            </button>
            <button
              @click="showPreview = true"
              :class="[
                'px-3 py-1 text-sm font-medium border-l-0 border',
                showPreview
                  ? 'bg-secondary-700 text-white border-secondary-700'
                  : 'bg-white text-secondary-700 border-secondary-300 hover:bg-secondary-50'
              ]"
            >
              <EyeIcon class="h-4 w-4 mr-1 inline" />
              Preview
            </button>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center space-x-2">
          <button
            @click="insertMarkdown('**', '**')"
            class="p-1 text-secondary-600 hover:text-secondary-900"
            title="Bold"
          >
            <strong>B</strong>
          </button>
          <button
            @click="insertMarkdown('*', '*')"
            class="p-1 text-secondary-600 hover:text-secondary-900 italic"
            title="Italic"
          >
            I
          </button>
          <button
            @click="insertMarkdown('[', '](url)')"
            class="p-1 text-secondary-600 hover:text-secondary-900"
            title="Link"
          >
            🔗
          </button>
          <button
            @click="insertMarkdown('![alt](', ')')"
            class="p-1 text-secondary-600 hover:text-secondary-900"
            title="Image"
          >
            📷
          </button>
          <button
            @click="insertCode"
            class="p-1 text-secondary-600 hover:text-secondary-900 font-mono"
            title="Code"
          >
            &lt;/&gt;
          </button>
        </div>
      </div>
    </div>

    <!-- Editor Content -->
    <div class="relative">
      <!-- Editor -->
      <div v-show="!showPreview" class="relative">
        <textarea
          ref="textareaRef"
          v-model="content"
          @input="$emit('update:modelValue', content)"
          :placeholder="placeholder"
          class="w-full border-0 resize-none focus:ring-0 focus:outline-none p-4 font-mono text-sm"
          :style="{ height: editorHeight + 'px' }"
        ></textarea>
        
        <!-- Character count -->
        <div class="absolute bottom-2 right-2 text-xs text-secondary-500 bg-white px-2 py-1 rounded shadow">
          {{ content.length }} characters
        </div>
      </div>

      <!-- Preview -->
      <div v-show="showPreview" class="relative">
        <div
          class="prose prose-secondary max-w-none p-4 overflow-auto"
          :style="{ height: editorHeight + 'px' }"
          v-html="renderedContent"
        ></div>
        
        <div class="absolute bottom-2 right-2 text-xs text-secondary-500 bg-white px-2 py-1 rounded shadow">
          Preview Mode
        </div>
      </div>
    </div>

    <!-- Image Upload Modal -->
    <div
      v-if="showImageUpload"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click="showImageUpload = false"
    >
      <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4" @click.stop>
        <h3 class="text-lg font-medium mb-4">Upload Image</h3>
        
        <div class="space-y-4">
          <!-- File Input -->
          <div>
            <input
              ref="fileInputRef"
              type="file"
              accept="image/*"
              @change="handleImageUpload"
              class="w-full text-sm text-secondary-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100"
            />
          </div>

          <!-- Upload Progress -->
          <div v-if="uploadProgress > 0" class="w-full bg-secondary-200 rounded-full h-2">
            <div
              class="bg-primary-600 h-2 rounded-full transition-all duration-300"
              :style="{ width: uploadProgress + '%' }"
            ></div>
          </div>

          <!-- Actions -->
          <div class="flex justify-end space-x-3">
            <button
              @click="showImageUpload = false"
              class="btn-outline btn-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, watch } from 'vue'
import { PencilIcon, EyeIcon } from '@heroicons/vue/24/outline'
import { uploadApi } from '@/services/resources'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: 'Start writing your content...'
  },
  height: {
    type: Number,
    default: 400
  }
})

const emit = defineEmits(['update:modelValue'])

// Reactive data
const content = ref(props.modelValue)
const isMarkdown = ref(true)
const showPreview = ref(false)
const showImageUpload = ref(false)
const uploadProgress = ref(0)
const textareaRef = ref(null)
const fileInputRef = ref(null)

// Computed
const editorHeight = computed(() => props.height)

const renderedContent = computed(() => {
  if (!content.value) return '<p class="text-secondary-500">Nothing to preview...</p>'
  
  // Simple markdown-to-HTML conversion
  // In a real app, you'd use a proper markdown parser like marked.js
  let html = content.value
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/`(.*?)`/g, '<code class="bg-secondary-100 px-1 rounded">$1</code>')
    .replace(/^# (.*$)/gm, '<h1 class="text-2xl font-bold mt-6 mb-4">$1</h1>')
    .replace(/^## (.*$)/gm, '<h2 class="text-xl font-bold mt-5 mb-3">$1</h2>')
    .replace(/^### (.*$)/gm, '<h3 class="text-lg font-bold mt-4 mb-2">$1</h3>')
    .replace(/^\> (.*$)/gm, '<blockquote class="border-l-4 border-secondary-300 pl-4 italic">$1</blockquote>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="text-primary-600 hover:text-primary-800 underline">$1</a>')
    .replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" class="max-w-full h-auto rounded-lg" />')
    .replace(/\n\n/g, '</p><p>')
    .replace(/\n/g, '<br>')
  
  return `<p>${html}</p>`.replace('<p></p>', '')
})

// Methods
const insertMarkdown = (before, after = '') => {
  const textarea = textareaRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = content.value.substring(start, end)
  
  const replacement = before + selectedText + after
  
  content.value = content.value.substring(0, start) + replacement + content.value.substring(end)
  
  emit('update:modelValue', content.value)
  
  // Restore cursor position
  nextTick(() => {
    textarea.focus()
    const newCursorPos = start + before.length + selectedText.length
    textarea.setSelectionRange(newCursorPos, newCursorPos)
  })
}

const insertCode = () => {
  const textarea = textareaRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = content.value.substring(start, end)
  
  let replacement
  if (selectedText.includes('\n') || selectedText.length > 50) {
    // Multi-line code block
    replacement = '\n```\n' + selectedText + '\n```\n'
  } else {
    // Inline code
    replacement = '`' + selectedText + '`'
  }
  
  content.value = content.value.substring(0, start) + replacement + content.value.substring(end)
  
  emit('update:modelValue', content.value)
  
  // Restore cursor position
  nextTick(() => {
    textarea.focus()
  })
}

const handleImageUpload = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  try {
    uploadProgress.value = 0
    
    const result = await uploadApi.uploadImage(file, (progress) => {
      uploadProgress.value = progress
    })

    // Insert image markdown
    const imageMarkdown = `![${file.name}](${result.data.url})`
    const textarea = textareaRef.value
    
    if (textarea) {
      const cursorPos = textarea.selectionStart
      content.value = content.value.substring(0, cursorPos) + imageMarkdown + content.value.substring(cursorPos)
      emit('update:modelValue', content.value)
    }

    showImageUpload.value = false
    uploadProgress.value = 0
    
    if (window.toast) {
      window.toast.success('Success', 'Image uploaded successfully!')
    }
  } catch (error) {
    console.error('Image upload failed:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to upload image. Please try again.')
    }
    uploadProgress.value = 0
  }
}

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  content.value = newValue
})

// Auto-resize textarea
const autoResize = () => {
  const textarea = textareaRef.value
  if (textarea) {
    textarea.style.height = 'auto'
    textarea.style.height = Math.min(textarea.scrollHeight, editorHeight.value) + 'px'
  }
}

onMounted(() => {
  if (textareaRef.value) {
    textareaRef.value.addEventListener('input', autoResize)
  }
})
</script>

<style scoped>
.prose {
  @apply leading-relaxed;
}

.prose h1, .prose h2, .prose h3 {
  @apply font-bold;
}

.prose p {
  @apply mb-4;
}

.prose blockquote {
  @apply my-4;
}

.prose img {
  @apply my-4;
}
</style>
