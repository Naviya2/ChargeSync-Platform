import { useState } from 'react'
import { useUsers, useCreateUser, useUpdateUser, useDeleteUser } from '../hooks/useUsers'
import PageHeader from '../../../components/shared/PageHeader'
import { Spinner } from '../../../components/ui'

const ROLE_MAP = {
  0: 'Driver',
  1: 'StationOwner',
  2: 'SystemAdmin'
}

export default function UsersPage() {
  const { data: users = [], isLoading } = useUsers()
  const createUser = useCreateUser()
  const updateUser = useUpdateUser()
  const deleteUser = useDeleteUser()

  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingUser, setEditingUser] = useState(null)
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    password: '',
    role: 0,
    phoneNumber: ''
  })

  const openModal = (user = null) => {
    if (user) {
      setEditingUser(user)
      setFormData({
        fullName: user.fullName || '',
        email: user.email || '',
        password: '',
        role: typeof user.role === 'number' ? user.role : (Object.keys(ROLE_MAP).find(k => ROLE_MAP[k] === user.role) || 0),
        phoneNumber: user.phoneNumber || ''
      })
    } else {
      setEditingUser(null)
      setFormData({
        fullName: '',
        email: '',
        password: '',
        role: 0,
        phoneNumber: ''
      })
    }
    setIsModalOpen(true)
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (editingUser) {
      updateUser.mutate({ id: editingUser.id, ...formData, role: Number(formData.role) }, {
        onSuccess: () => setIsModalOpen(false)
      })
    } else {
      createUser.mutate({ ...formData, role: Number(formData.role) }, {
        onSuccess: () => setIsModalOpen(false)
      })
    }
  }

  const handleDelete = (id) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      deleteUser.mutate(id)
    }
  }

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <PageHeader
          title="User Management"
          description="Manage system access for drivers, station owners, and administrators."
        />
        <button
          onClick={() => openModal()}
          className="inline-flex items-center gap-space-xs rounded-xl bg-gradient-to-r from-primary to-tertiary px-space-lg py-space-xs font-label-md text-label-md text-on-primary shadow-md transition-all hover:brightness-105"
        >
          <span className="material-symbols-outlined text-base">person_add</span>
          <span>Add New User</span>
        </button>
      </div>

      <div className="overflow-hidden rounded-xl bg-surface-container-lowest shadow-sm">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center p-16">
            <Spinner />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-surface-container-low border-b border-surface-container">
                <tr>
                  <th className="px-6 py-4 font-label-sm text-on-surface-variant uppercase tracking-wider">Name</th>
                  <th className="px-6 py-4 font-label-sm text-on-surface-variant uppercase tracking-wider">Email</th>
                  <th className="px-6 py-4 font-label-sm text-on-surface-variant uppercase tracking-wider">Role</th>
                  <th className="px-6 py-4 font-label-sm text-on-surface-variant uppercase tracking-wider">Status</th>
                  <th className="px-6 py-4 font-label-sm text-on-surface-variant uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container">
                {users.map((user) => (
                  <tr key={user.id} className="hover:bg-surface-container-low/50 transition-colors">
                    <td className="px-6 py-4 font-medium text-on-surface">{user.fullName}</td>
                    <td className="px-6 py-4 text-on-surface-variant">{user.email}</td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center rounded-full bg-secondary-container/20 px-2.5 py-1 text-xs font-medium text-secondary">
                        {ROLE_MAP[user.role] || user.role || 'User'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {user.isActive ? (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-tertiary-container/20 px-2.5 py-1 text-xs font-medium text-tertiary">
                          <span className="h-1.5 w-1.5 rounded-full bg-tertiary"></span>
                          Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-error-container/20 px-2.5 py-1 text-xs font-medium text-error">
                          <span className="h-1.5 w-1.5 rounded-full bg-error"></span>
                          Inactive
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <button onClick={() => openModal(user)} className="p-1 text-on-surface-variant hover:text-primary transition-colors">
                          <span className="material-symbols-outlined text-[20px]">edit</span>
                        </button>
                        <button onClick={() => handleDelete(user.id)} className="p-1 text-on-surface-variant hover:text-error transition-colors">
                          <span className="material-symbols-outlined text-[20px]">delete</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {users.length === 0 && (
                  <tr>
                    <td colSpan="5" className="px-6 py-12 text-center text-on-surface-variant">
                      No users found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* User Form Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm">
          <div className="w-full max-w-lg rounded-2xl bg-surface-container-lowest shadow-lg">
            <div className="flex items-center justify-between border-b border-surface-container p-6">
              <h2 className="text-xl font-semibold text-on-surface">{editingUser ? 'Edit User' : 'Add New User'}</h2>
              <button onClick={() => setIsModalOpen(false)} className="text-on-surface-variant hover:text-on-surface">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-on-surface">Full Name</label>
                <input
                  required
                  type="text"
                  value={formData.fullName}
                  onChange={e => setFormData({ ...formData, fullName: e.target.value })}
                  className="w-full rounded-xl border border-outline-variant bg-transparent p-3 text-sm text-on-surface focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-on-surface">Email Address</label>
                <input
                  required
                  type="email"
                  value={formData.email}
                  onChange={e => setFormData({ ...formData, email: e.target.value })}
                  className="w-full rounded-xl border border-outline-variant bg-transparent p-3 text-sm text-on-surface focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-on-surface">Password {editingUser && '(Leave blank to keep current)'}</label>
                <input
                  required={!editingUser}
                  type="password"
                  value={formData.password}
                  onChange={e => setFormData({ ...formData, password: e.target.value })}
                  className="w-full rounded-xl border border-outline-variant bg-transparent p-3 text-sm text-on-surface focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-on-surface">Role</label>
                <select
                  value={formData.role}
                  onChange={e => setFormData({ ...formData, role: e.target.value })}
                  className="w-full rounded-xl border border-outline-variant bg-transparent p-3 text-sm text-on-surface focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                >
                  <option value={0}>Driver</option>
                  <option value={1}>Station Owner</option>
                  <option value={2}>System Admin</option>
                </select>
              </div>
              <div className="flex justify-end gap-3 pt-4 border-t border-surface-container">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="rounded-xl px-5 py-2.5 text-sm font-medium text-on-surface-variant hover:bg-surface-container"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createUser.isPending || updateUser.isPending}
                  className="rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-on-primary hover:brightness-105 disabled:opacity-50"
                >
                  {editingUser ? 'Save Changes' : 'Create User'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
