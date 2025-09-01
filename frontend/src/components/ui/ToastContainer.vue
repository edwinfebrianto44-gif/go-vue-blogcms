<template>
  <div class="fixed top-4 right-4 z-50 space-y-2">
    <transition-group name="toast" tag="div">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        :class="[
          'max-w-sm w-full bg-white shadow-lg rounded-lg pointer-events-auto ring-1 ring-black ring-opacity-5 overflow-hidden',
          toastClasses[toast.type]
        ]"
      >
        <div class="p-4">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <CheckCircleIcon v-if="toast.type === 'success'" class="h-6 w-6 text-green-400" />
              <ExclamationTriangleIcon v-else-if="toast.type === 'warning'" class="h-6 w-6 text-yellow-400" />
              <XCircleIcon v-else-if="toast.type === 'error'" class="h-6 w-6 text-red-400" />
              <InformationCircleIcon v-else class="h-6 w-6 text-blue-400" />
            </div>
            <div class="ml-3 w-0 flex-1">
              <p class="text-sm font-medium text-gray-900">{{ toast.title }}</p>
              <p v-if="toast.message" class="mt-1 text-sm text-gray-500">{{ toast.message }}</p>
            </div>
            <div class="ml-4 flex-shrink-0 flex">
              <button
                @click="removeToast(toast.id)"
                class="bg-white rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <span class="sr-only">Close</span>
                <XMarkIcon class="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition-group>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  XCircleIcon,
  InformationCircleIcon,
  XMarkIcon
} from '@heroicons/vue/24/outline'

const toasts = ref([])

const toastClasses = {
  success: 'border-l-4 border-green-400',
  warning: 'border-l-4 border-yellow-400',
  error: 'border-l-4 border-red-400',
  info: 'border-l-4 border-blue-400'
}

let toastId = 0

const addToast = (toast) => {
  const id = ++toastId
  const newToast = {
    id,
    type: toast.type || 'info',
    title: toast.title,
    message: toast.message,
    duration: toast.duration || 5000
  }
  
  toasts.value.push(newToast)
  
  // Auto remove after duration
  setTimeout(() => {
    removeToast(id)
  }, newToast.duration)
}

const removeToast = (id) => {
  const index = toasts.value.findIndex(toast => toast.id === id)
  if (index !== -1) {
    toasts.value.splice(index, 1)
  }
}

// Expose methods globally
window.toast = {
  success: (title, message) => addToast({ type: 'success', title, message }),
  warning: (title, message) => addToast({ type: 'warning', title, message }),
  error: (title, message) => addToast({ type: 'error', title, message }),
  info: (title, message) => addToast({ type: 'info', title, message })
}

defineExpose({
  addToast,
  removeToast
})
</script>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%);
}

.toast-move {
  transition: transform 0.3s ease;
}
</style>
