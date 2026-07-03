'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { AlertCircle, CheckCircle2, Info, X } from 'lucide-react';

export interface ConfirmationOptions {
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'info' | 'success';
}

interface ConfirmationModalProps extends ConfirmationOptions {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
}

export default function ConfirmationModal({
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant = 'info',
  onClose,
  onConfirm,
}: ConfirmationModalProps) {
  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4">
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        className="absolute inset-0 bg-zinc-950/60 backdrop-blur-md"
      />

      {/* Modal Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.9, y: 20 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className="relative w-full max-w-md bg-white rounded-[2.5rem] shadow-2xl overflow-hidden border border-zinc-100"
      >
        {/* Header Decor */}
        <div className={`h-32 flex items-center justify-center relative overflow-hidden ${
          variant === 'danger' ? 'bg-gradient-to-br from-red-500 to-rose-600' :
          variant === 'success' ? 'bg-gradient-to-br from-emerald-500 to-teal-600' :
          'bg-gradient-to-br from-blue-500 to-indigo-600'
        }`}>
          <div className="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-white via-transparent to-transparent"></div>
          
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4 animate-in zoom-in-50 duration-500">
            {variant === 'danger' && <AlertCircle className="w-10 h-10 text-white" />}
            {variant === 'success' && <CheckCircle2 className="w-10 h-10 text-white" />}
            {variant === 'info' && <Info className="w-10 h-10 text-white" />}
          </div>

          <button 
            onClick={onClose}
            className="absolute top-6 right-6 p-2 rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="p-8 text-center">
          <p className={`text-[10px] font-black uppercase tracking-[0.2em] mb-2 ${
            variant === 'danger' ? 'text-red-500' :
            variant === 'success' ? 'text-emerald-500' :
            'text-blue-500'
          }`}>
            {variant === 'danger' ? 'Risk Alert' : 'System Notice'}
          </p>
          <h3 className="text-2xl font-black text-zinc-900 tracking-tight mb-4">{title}</h3>
          
          <p className="text-sm font-medium text-zinc-500 mb-8 leading-relaxed px-4">
            {message}
          </p>

          <div className="flex gap-3 mt-4">
            <button
              onClick={onClose}
              className="flex-1 rounded-2xl bg-zinc-50 text-zinc-400 py-4 text-xs font-black uppercase tracking-[0.15em] hover:bg-zinc-100 hover:text-zinc-600 transition-all active:scale-[0.98]"
            >
              {cancelLabel}
            </button>
            <button
              onClick={onConfirm}
              className={`flex-1 rounded-2xl text-white py-4 text-xs font-black uppercase tracking-[0.15em] shadow-xl transition-all active:scale-[0.98] ${
                variant === 'danger' ? 'bg-[#6C3DFF] hover:bg-rose-700 shadow-rose-100' :
                variant === 'success' ? 'bg-emerald-600 hover:bg-emerald-700 shadow-emerald-100' :
                'bg-blue-600 hover:bg-blue-700 shadow-blue-100'
              }`}
            >
              {confirmLabel}
            </button>
          </div>
        </div>
      </motion.div>
    </div>
  );
}
