import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import { useNotificationStore } from '../../store/notificationStore'
import { useMyStations, useStations } from '../../features/stations/hooks/useStations'
import { ROUTES } from '../../lib/constants'
import useDialogStore from '../../store/dialogStore'

export default function Topbar() {
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const clearSession = useAuthStore((s) => s.clearSession)
  
  const notifications = useNotificationStore((s) => s.notifications)
  const dismissNotification = useNotificationStore((s) => s.dismiss)
  const notify = useNotificationStore((s) => s.notify)

  const { data: myStations = [] } = useMyStations()
  const { data: allStations = [] } = useStations()
  
  const role = user?.role
  const stationsList = (role === 'Admin' || role === 2) ? allStations : myStations;
  const activeChargersCount = stationsList.reduce((acc, st) => acc + (st.chargers?.length || 0), 0)

  const [showProfile, setShowProfile] = useState(false)
  const [showNotifs, setShowNotifs] = useState(false)
  
  // Modals state
  const [showProfileModal, setShowProfileModal] = useState(false)
  const [showPasswordModal, setShowPasswordModal] = useState(false)

  // Dark Mode state
  const [darkMode, setDarkMode] = useState(localStorage.getItem('theme') === 'dark')
  
  // Password form state
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordError, setPasswordError] = useState('')
  
  const profileRef = useRef(null)
  const notifRef = useRef(null)

  // Handle click outside for dropdowns
  useEffect(() => {
    function handleClickOutside(event) {
      if (profileRef.current && !profileRef.current.contains(event.target)) {
        setShowProfile(false)
      }
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setShowNotifs(false)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  // Apply dark mode
  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    } else {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    }
  }, [darkMode])

  const handleLogout = () => {
    clearSession()
    navigate(ROUTES.LOGIN, { replace: true })
  }

  const handlePasswordSubmit = (e) => {
    e.preventDefault()
    setPasswordError('')
    
    if (newPassword === currentPassword) {
      setPasswordError('New password cannot be the same as your current password.')
      return
    }
    
    if (newPassword !== confirmPassword) {
      setPasswordError('New password and confirm password do not match.')
      return
    }

    if (newPassword.length < 8) {
      setPasswordError('Password must be at least 8 characters long.')
      return
    }
    
    // Simulate success
    useDialogStore.getState().alert({ title: 'Password Updated', message: 'Your password has been changed successfully.', variant: 'success' })
    setShowPasswordModal(false)
    setCurrentPassword('')
    setNewPassword('')
    setConfirmPassword('')
  }

  const initials = (user?.name ?? 'G')
    .split(' ')
    .map((w) => w[0])
    .slice(0, 2)
    .join('')

  return (
    <>
      <header className="sticky top-0 z-30 h-topbar-height bg-surface-container-lowest/90 shadow-[0_1px_8px_rgba(0,0,0,0.04)] backdrop-blur-md">
        <div className="flex h-topbar-height w-full items-center justify-between gap-space-lg px-gutter-desktop">
          
          <div className="flex flex-1 items-center gap-4">
            {/* Left space empty */}
          </div>

          {/* Right controls */}
          <div className="flex items-center gap-space-md">
            <div className="hidden items-center gap-space-xs rounded-full bg-surface-container-low px-space-md py-space-xs font-label-md text-label-md text-on-surface lg:flex">
              <span className="h-2 w-2 rounded-full bg-tertiary" />
              <span>{activeChargersCount} Chargers</span>
            </div>

            <button 
              onClick={() => setDarkMode(!darkMode)}
              className="flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-600 shadow-sm transition hover:bg-gray-50 hover:text-gray-900 focus:outline-none"
              title={darkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}
            >
              <span className="material-symbols-outlined text-xl">{darkMode ? 'light_mode' : 'dark_mode'}</span>
            </button>

            <div className="relative" ref={notifRef}>
              <button
                type="button"
                onClick={() => {
                  setShowNotifs(!showNotifs)
                  setShowProfile(false)
                }}
                className="relative flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-600 shadow-sm transition hover:bg-gray-50 hover:text-gray-900 focus:outline-none"
                aria-label="Notifications"
              >
                <span className="material-symbols-outlined text-xl">notifications</span>
                {notifications.length > 0 && (
                  <span className="absolute right-1 top-1 flex h-4 w-4 items-center justify-center rounded-full bg-error text-[10px] text-white">
                    {notifications.length}
                  </span>
                )}
              </button>
              
              {showNotifs && (
                <div className="absolute right-0 mt-2 w-80 rounded-xl bg-white shadow-lg ring-1 ring-black ring-opacity-5 overflow-hidden">
                  <div className="px-4 py-3 border-b border-gray-100 bg-gray-50 flex justify-between items-center">
                    <h3 className="text-sm font-semibold text-gray-900">Notifications</h3>
                    <span className="text-xs bg-blue-100 text-blue-800 py-0.5 px-2 rounded-full">{notifications.length} New</span>
                  </div>
                  <div className="max-h-96 overflow-y-auto">
                    {notifications.length === 0 ? (
                      <div className="px-4 py-6 text-sm text-gray-500 text-center">No new notifications</div>
                    ) : (
                      notifications.map(n => (
                        <div key={n.id} className="px-4 py-3 hover:bg-gray-50 border-b border-gray-100 relative group">
                          <div className="flex justify-between items-start">
                            <p className="text-sm font-medium text-gray-900">{n.title || 'Notification'}</p>
                            <button onClick={() => dismissNotification(n.id)} className="text-gray-400 hover:text-gray-600 opacity-0 group-hover:opacity-100 transition-opacity">
                              <span className="material-symbols-outlined text-sm">close</span>
                            </button>
                          </div>
                          <p className="text-xs text-gray-500 mt-1">{n.message}</p>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>

            <div className="relative" ref={profileRef}>
              <button
                onClick={() => {
                  setShowProfile(!showProfile)
                  setShowNotifs(false)
                }}
                className="flex h-10 items-center gap-2 rounded-full border border-gray-200 bg-white pl-2 pr-4 shadow-sm transition hover:shadow-md focus:outline-none"
              >
                <span className="flex h-7 w-7 items-center justify-center rounded-full bg-primary/10 font-label-sm text-label-sm font-bold text-primary">
                  {initials}
                </span>
                <span className="text-sm font-medium text-gray-700 hidden sm:block">{user?.name || 'User Profile'}</span>
                <span className="material-symbols-outlined text-gray-400 text-sm">expand_more</span>
              </button>

              {showProfile && (
                <div className="absolute right-0 mt-2 w-56 rounded-xl bg-white shadow-lg ring-1 ring-black ring-opacity-5 divide-y divide-gray-100">
                  <div className="px-4 py-3">
                    <p className="text-sm text-gray-900 font-medium">{user?.name || 'User Profile'}</p>
                    <p className="text-xs text-gray-500 truncate">{user?.email || 'user@example.com'}</p>
                    <span className="inline-block mt-2 px-2 py-0.5 bg-blue-100 text-blue-800 text-[10px] font-bold rounded-full uppercase tracking-wider">{user?.role}</span>
                  </div>
                  <div className="py-1">
                    <button onClick={() => { setShowProfileModal(true); setShowProfile(false); }} className="flex w-full items-center gap-3 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                      <span className="material-symbols-outlined text-lg text-gray-400">person</span>
                      Your Profile
                    </button>
                    <button onClick={() => { setShowPasswordModal(true); setShowProfile(false); }} className="flex w-full items-center gap-3 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                      <span className="material-symbols-outlined text-lg text-gray-400">lock</span>
                      Change Password
                    </button>
                  </div>
                  <div className="py-1">
                    <button
                      onClick={handleLogout}
                      className="flex w-full items-center gap-3 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                    >
                      <span className="material-symbols-outlined text-lg text-red-500">logout</span>
                      Sign out
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Modals placed outside header to avoid z-index stacking issues */}
      {showProfileModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-2xl overflow-hidden flex flex-col">
            
            <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-6 flex flex-col items-center border-b border-gray-100">
              <div className="flex h-20 w-20 items-center justify-center rounded-full bg-white shadow-sm border border-gray-200 text-3xl font-bold text-primary mb-3">
                {initials}
              </div>
              <h2 className="text-xl font-bold text-gray-900">{user?.name}</h2>
              <span className="inline-block mt-1 px-3 py-1 bg-blue-100 text-blue-800 text-[10px] font-bold rounded-full uppercase tracking-wider">{user?.role}</span>
            </div>
            
            <div className="p-6 space-y-4">
              <div className="flex flex-col bg-gray-50 p-4 rounded-xl border border-gray-100">
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Email Address</label>
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-gray-400 text-sm">mail</span>
                  <p className="font-medium text-gray-900">{user?.email}</p>
                </div>
              </div>
            </div>
            
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/50 flex justify-end">
              <button onClick={() => setShowProfileModal(false)} className="rounded-xl bg-blue-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 transition w-full sm:w-auto">
                Done
              </button>
            </div>
            
          </div>
        </div>
      )}

      {showPasswordModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-2xl overflow-hidden flex flex-col">
            
            <div className="p-6 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-50 text-blue-600">
                  <span className="material-symbols-outlined">lock_reset</span>
                </div>
                <div>
                  <h2 className="text-lg font-bold text-gray-900">Change Password</h2>
                  <p className="text-sm text-gray-500">Update your account security.</p>
                </div>
              </div>
            </div>

            <div className="p-6">
              {passwordError && (
                <div className="mb-6 flex items-center gap-2 rounded-xl bg-red-50 p-3 text-sm text-red-700 border border-red-100">
                  <span className="material-symbols-outlined text-red-500 text-lg">error</span>
                  {passwordError}
                </div>
              )}
              <form id="password-form" className="space-y-5" onSubmit={handlePasswordSubmit}>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Current Password</label>
                  <div className="relative">
                    <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">key</span>
                    <input 
                      type="password" 
                      required 
                      className="block w-full rounded-xl border border-gray-200 bg-gray-50 py-2.5 pl-9 pr-3 text-sm text-gray-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition" 
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                    />
                  </div>
                </div>
                
                <div className="pt-2">
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">New Password</label>
                  <div className="relative">
                    <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">lock</span>
                    <input 
                      type="password" 
                      required 
                      className="block w-full rounded-xl border border-gray-200 bg-gray-50 py-2.5 pl-9 pr-3 text-sm text-gray-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition" 
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                    />
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Confirm New Password</label>
                  <div className="relative">
                    <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">lock_clock</span>
                    <input 
                      type="password" 
                      required 
                      className="block w-full rounded-xl border border-gray-200 bg-gray-50 py-2.5 pl-9 pr-3 text-sm text-gray-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition" 
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                    />
                  </div>
                </div>
              </form>
            </div>
            
            <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/50 flex justify-end gap-3">
              <button 
                type="button" 
                onClick={() => {
                  setShowPasswordModal(false);
                  setPasswordError('');
                  setCurrentPassword('');
                  setNewPassword('');
                  setConfirmPassword('');
                }} 
                className="rounded-xl px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-100 transition w-full sm:w-auto"
              >
                Cancel
              </button>
              <button type="submit" form="password-form" className="rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 transition w-full sm:w-auto">
                Update Password
              </button>
            </div>
            
          </div>
        </div>
      )}
    </>
  )
}
