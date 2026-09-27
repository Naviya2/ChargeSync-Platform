import { useState, useCallback } from 'react'
import { cn } from '../../lib/cn'

async function generateSHA1(message) {
  const msgBuffer = new TextEncoder().encode(message)
  const hashBuffer = await crypto.subtle.digest('SHA-1', msgBuffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

export default function ImageUploader({ urls, onChange, className }) {
  const [isUploading, setIsUploading] = useState(false)
  const [error, setError] = useState(null)

  const handleFileChange = useCallback(async (e) => {
    const files = Array.from(e.target.files)
    if (files.length === 0) return

    setIsUploading(true)
    setError(null)
    const uploadedUrls = []

    try {
      const cloudName = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME
      const apiKey = import.meta.env.VITE_CLOUDINARY_API_KEY
      const apiSecret = import.meta.env.VITE_CLOUDINARY_API_SECRET

      if (!cloudName || !apiKey || !apiSecret) {
        throw new Error('Cloudinary environment variables are not properly configured.')
      }

      for (const file of files) {
        if (!file.type.startsWith('image/')) {
          setError('Only image files are allowed.')
          continue
        }

        const timestamp = Math.floor(Date.now() / 1000).toString()
        const signatureString = `timestamp=${timestamp}${apiSecret}`
        const signature = await generateSHA1(signatureString)

        const formData = new FormData()
        formData.append('file', file)
        formData.append('api_key', apiKey)
        formData.append('timestamp', timestamp)
        formData.append('signature', signature)

        const response = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/image/upload`, {
          method: 'POST',
          body: formData,
        })

        if (!response.ok) {
          const errData = await response.json()
          throw new Error(errData.error?.message || 'Upload failed')
        }

        const data = await response.json()
        uploadedUrls.push(data.secure_url)
      }

      if (uploadedUrls.length > 0) {
        onChange([...urls, ...uploadedUrls])
      }
    } catch (err) {
      console.error('Cloudinary upload error:', err)
      setError(err.message || 'Failed to upload image(s).')
    } finally {
      setIsUploading(false)
      e.target.value = ''
    }
  }, [urls, onChange])

  const handleRemove = (urlToRemove) => {
    onChange(urls.filter(url => url !== urlToRemove))
  }

  return (
    <div className={cn('flex flex-col gap-space-sm', className)}>
      <label className="font-label-md text-label-md text-on-surface">
        Business Documents (Proof of Ownership, IDs, etc.)
      </label>

      <div className="flex flex-wrap gap-space-sm">
        {urls.map((url, index) => (
          <div key={index} className="relative h-24 w-24 rounded-lg overflow-hidden border border-outline shadow-sm group">
            <img src={url} alt={`Document ${index + 1}`} className="h-full w-full object-cover" />
            <button
              type="button"
              onClick={() => handleRemove(url)}
              className="absolute top-1 right-1 bg-surface/80 p-1 rounded-full text-on-surface-variant hover:text-error hover:bg-surface backdrop-blur-sm opacity-0 group-hover:opacity-100 transition-opacity"
              title="Remove document"
            >
              <span className="material-symbols-outlined text-[16px]">close</span>
            </button>
          </div>
        ))}

        <label className={cn(
          "flex flex-col items-center justify-center h-24 w-24 rounded-lg border-2 border-dashed border-outline-variant bg-surface-container-lowest hover:bg-surface-container-low hover:border-primary transition-colors cursor-pointer",
          isUploading && "opacity-50 pointer-events-none"
        )}>
          {isUploading ? (
            <span className="material-symbols-outlined text-primary animate-spin">refresh</span>
          ) : (
            <>
              <span className="material-symbols-outlined text-on-surface-variant">add_photo_alternate</span>
              <span className="text-[10px] text-on-surface-variant mt-1 font-medium">Upload</span>
            </>
          )}
          <input
            type="file"
            multiple
            accept="image/*"
            className="hidden"
            onChange={handleFileChange}
            disabled={isUploading}
          />
        </label>
      </div>

      {error && <span className="text-error font-body-xs">{error}</span>}
    </div>
  )
}
