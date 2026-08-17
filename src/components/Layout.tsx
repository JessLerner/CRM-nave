import React from 'react';
import { Outlet, NavLink } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { LayoutDashboard, Users, User, LogOut, Settings, BarChart2 } from 'lucide-react';

export default function Layout() {
  const { profile, signOut } = useAuth();

  const navItems = [
    { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
    { to: '/leads', icon: Users, label: 'Leads' },
    ...(profile?.role === 'admin' || profile?.role === 'supervisor' ? [
      { to: '/metrics', icon: BarChart2, label: 'Métricas' },
    ] : []),
    ...(profile?.role === 'admin' ? [
      { to: '/admin', icon: Settings, label: 'Administración' },
    ] : []),
  ];

  return (
    <div className="min-h-screen bg-neutral-50 flex">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-neutral-200 flex flex-col fixed h-full z-10">
        <div className="p-6 border-b border-neutral-200">
          <h1 className="text-xl font-bold text-blue-700 tracking-tight">PROMPT MAESTRO</h1>
          <div className="mt-2 flex items-center gap-2 text-sm text-neutral-600">
            <span className="w-2 h-2 rounded-full bg-green-500"></span>
            Conectado como <span className="font-medium capitalize">{profile?.role}</span>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-lg font-medium transition-colors ${
                  isActive
                    ? 'bg-blue-50 text-blue-700'
                    : 'text-neutral-600 hover:bg-neutral-100 hover:text-neutral-900'
                }`
              }
            >
              <item.icon className="w-5 h-5" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-neutral-200">
          <div className="flex items-center gap-3 px-3 py-2 mb-2">
            <div className="bg-blue-100 text-blue-700 w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shrink-0">
              {profile?.first_name?.[0] || profile?.email?.[0]?.toUpperCase()}
            </div>
            <div className="overflow-hidden">
              <p className="text-sm font-medium text-neutral-900 truncate">
                {profile?.first_name} {profile?.last_name}
              </p>
              <p className="text-xs text-neutral-500 truncate">{profile?.email}</p>
            </div>
          </div>
          <button
            onClick={signOut}
            className="w-full flex items-center gap-3 px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Cerrar Sesión
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 ml-64 flex flex-col min-h-screen">
        <div className="p-8 flex-1">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
