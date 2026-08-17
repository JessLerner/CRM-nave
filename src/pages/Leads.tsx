import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../hooks/useAuth';
import { Phone, MessageCircle, Calendar, Plus } from 'lucide-react';
import { format } from 'date-fns';

export default function Leads() {
  const { profile } = useAuth();
  const [leads, setLeads] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchLeads();
  }, [profile]);

  const fetchLeads = async () => {
    try {
      setLoading(true);
      
      let query = supabase.from('leads').select('*, profiles!assigned_to(first_name, last_name)').order('created_at', { ascending: false });
      
      if (profile?.role === 'salesperson') {
        query = query.eq('assigned_to', profile.id);
      } else if (profile?.role === 'supervisor') {
        // En una app real, buscaríamos los leads del equipo.
        if (profile.team_id) {
          query = query.eq('team_id', profile.team_id);
        }
      }
      
      const { data, error } = await query;
      if (error) throw error;
      
      setLeads(data || []);
    } catch (err) {
      console.error('Error fetching leads', err);
    } finally {
      setLoading(false);
    }
  };

  const statusColors: Record<string, string> = {
    new: 'bg-blue-100 text-blue-800 border-blue-200',
    contacting: 'bg-amber-100 text-amber-800 border-amber-200',
    interested: 'bg-green-100 text-green-800 border-green-200',
    sold: 'bg-emerald-100 text-emerald-800 border-emerald-200',
    lost: 'bg-neutral-100 text-neutral-800 border-neutral-200',
  };

  const getStatusColor = (status: string) => statusColors[status] || 'bg-neutral-100 text-neutral-800';

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-neutral-900">Gestión de Leads</h1>
        <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium flex items-center gap-2 transition-colors">
          <Plus className="w-5 h-5" /> Nuevo Lead
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-neutral-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200 text-sm font-semibold text-neutral-600 uppercase tracking-wider">
                <th className="px-6 py-4">Cliente</th>
                <th className="px-6 py-4">Contacto</th>
                <th className="px-6 py-4">Estado</th>
                <th className="px-6 py-4">Asignado</th>
                <th className="px-6 py-4">Fecha</th>
                <th className="px-6 py-4 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-neutral-500">
                    Cargando leads...
                  </td>
                </tr>
              ) : leads.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-neutral-500">
                    No hay leads para mostrar.
                  </td>
                </tr>
              ) : (
                leads.map((lead) => (
                  <tr key={lead.id} className="hover:bg-neutral-50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="font-medium text-neutral-900">{lead.first_name} {lead.last_name}</div>
                      <div className="text-sm text-neutral-500">{lead.source} {lead.campaign && `- ${lead.campaign}`}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-neutral-900">{lead.phone}</div>
                      <div className="text-sm text-neutral-500">{lead.email}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusColor(lead.status)} capitalize`}>
                        {lead.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-neutral-600">
                      {lead.profiles ? `${lead.profiles.first_name} ${lead.profiles.last_name}` : 'Sin asignar'}
                    </td>
                    <td className="px-6 py-4 text-sm text-neutral-600">
                      {format(new Date(lead.created_at), 'dd/MM/yyyy HH:mm')}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex justify-end gap-2">
                        <button className="p-1.5 text-neutral-500 hover:text-green-600 hover:bg-green-50 rounded transition-colors" title="WhatsApp">
                          <MessageCircle className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 text-neutral-500 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors" title="Llamar">
                          <Phone className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 text-neutral-500 hover:text-amber-600 hover:bg-amber-50 rounded transition-colors" title="Seguimiento">
                          <Calendar className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
