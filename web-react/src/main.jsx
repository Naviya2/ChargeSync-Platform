import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClientProvider } from '@tanstack/react-query'
import { queryClient } from './lib/queryClient'
import AppRouter from './routes/AppRouter'
import GlobalDialogProvider from './components/ui/GlobalDialogProvider'
import './styles/index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <AppRouter />
      <GlobalDialogProvider />
    </QueryClientProvider>
  </React.StrictMode>,
)
