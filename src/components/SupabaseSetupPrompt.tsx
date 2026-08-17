import React from 'react';
import { Database, Key, Settings, AlertTriangle } from 'lucide-react';

export default function SupabaseSetupPrompt() {
  return (
    <div className="min-h-screen bg-neutral-50 flex flex-col items-center justify-center p-4 font-sans text-neutral-800">
      <div className="max-w-2xl w-full bg-white rounded-2xl shadow-xl border border-neutral-100 overflow-hidden">
        <div className="bg-blue-600 p-8 text-white text-center">
          <Database className="w-16 h-16 mx-auto mb-4 opacity-90" />
          <h1 className="text-3xl font-bold tracking-tight mb-2">PROMPT MAESTRO</h1>
          <p className="text-blue-100 text-lg">Configuración de Base de Datos Requerida</p>
        </div>
        
        <div className="p-8 space-y-8">
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 flex gap-4 text-amber-800">
            <AlertTriangle className="w-6 h-6 shrink-0 mt-0.5" />
            <div>
              <h3 className="font-semibold mb-1">MVP Funcional con Supabase</h3>
              <p className="text-sm opacity-90 leading-relaxed">
                Tal como solicitaste, esta aplicación está construida para conectarse <strong>realmente a Supabase</strong> (Auth + Database + RLS). 
                Para que la aplicación funcione y deje de mostrar esta pantalla, necesitas conectar tu proyecto de Supabase.
              </p>
            </div>
          </div>

          <div>
            <h2 className="text-xl font-semibold mb-4 flex items-center gap-2">
              <Settings className="w-5 h-5 text-neutral-500" />
              Pasos para conectar:
            </h2>
            <ol className="space-y-6">
              <li className="flex gap-4">
                <div className="bg-blue-100 text-blue-700 w-8 h-8 rounded-full flex items-center justify-center font-bold shrink-0">1</div>
                <div>
                  <p className="font-medium mb-1">Ejecuta el script SQL</p>
                  <p className="text-sm text-neutral-600">
                    Abre tu proyecto en Supabase, ve a <strong>SQL Editor</strong>, y pega el contenido del archivo <code className="bg-neutral-100 px-1.5 py-0.5 rounded text-neutral-800 font-mono text-xs">supabase/schema.sql</code> que se ha generado en esta plataforma. Ejecútalo para crear las tablas y políticas.
                  </p>
                </div>
              </li>
              <li className="flex gap-4">
                <div className="bg-blue-100 text-blue-700 w-8 h-8 rounded-full flex items-center justify-center font-bold shrink-0">2</div>
                <div>
                  <p className="font-medium mb-1">Configura las Variables de Entorno</p>
                  <p className="text-sm text-neutral-600 mb-2">
                    Ve a las <strong>Settings (Configuración)</strong> de este proyecto en AI Studio y añade las siguientes variables desde los ajustes de API de Supabase:
                  </p>
                  <div className="bg-neutral-900 rounded-lg p-4 text-sm font-mono text-green-400 overflow-x-auto">
                    VITE_SUPABASE_URL="https://tu-proyecto.supabase.co"<br/>
                    VITE_SUPABASE_ANON_KEY="tu-clave-anonima"
                  </div>
                </div>
              </li>
              <li className="flex gap-4">
                <div className="bg-blue-100 text-blue-700 w-8 h-8 rounded-full flex items-center justify-center font-bold shrink-0">3</div>
                <div>
                  <p className="font-medium mb-1">Recarga la Aplicación</p>
                  <p className="text-sm text-neutral-600">
                    Una vez configuradas las variables, la aplicación detectará la conexión y te permitirá iniciar sesión o registrarte.
                  </p>
                </div>
              </li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
