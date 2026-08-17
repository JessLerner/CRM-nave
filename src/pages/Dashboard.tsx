import React from 'react';
import { useAuth } from '../hooks/useAuth';

export default function Dashboard() {
  const { profile } = useAuth();

  return (
    <div>
      <h1 className="text-2xl font-bold text-neutral-900 mb-6">Dashboard</h1>
      
      <div className="bg-white rounded-xl shadow-sm border border-neutral-200 p-6">
        <h2 className="text-lg font-semibold mb-4">Bienvenido, {profile?.first_name || 'Usuario'}</h2>
        <p className="text-neutral-600">
          Tu rol actual es: <strong className="capitalize">{profile?.role}</strong>.
          <br/>
          Desde aquí podrás ver tus leads pendientes y estadísticas principales.
        </p>
      </div>
    </div>
  );
}
