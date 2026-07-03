'use client';

import React, { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import ConfirmationModal, { ConfirmationOptions } from '@/components/basic/confirmation-modal';
import { AnimatePresence, motion } from 'framer-motion';

interface ToastState {
  message: string;
  type: 'success' | 'error' | 'info';
}

interface UIContextType {
  confirm: (options: ConfirmationOptions) => Promise<boolean>;
  showToast: (message: string, type?: 'success' | 'error' | 'info') => void;
}

const UIContext = createContext<UIContextType | undefined>(undefined);

export function UIProvider({ children }: { children: ReactNode }) {
  const [confirmOptions, setConfirmOptions] = useState<ConfirmationOptions | null>(null);
  const [confirmPromise, setConfirmPromise] = useState<{ resolve: (value: boolean) => void } | null>(null);
  const [toast, setToast] = useState<ToastState | null>(null);

  const confirm = useCallback((options: ConfirmationOptions): Promise<boolean> => {
    setConfirmOptions(options);
    return new Promise((resolve) => {
      setConfirmPromise({ resolve });
    });
  }, []);

  const handleConfirm = useCallback((value: boolean) => {
    if (confirmPromise) {
      confirmPromise.resolve(value);
    }
    setConfirmOptions(null);
    setConfirmPromise(null);
  }, [confirmPromise]);

  const showToast = useCallback((message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  }, []);

  return (
    <UIContext.Provider value={{ confirm, showToast }}>
      {children}

      {/* Global Confirmation Modal */}
      <AnimatePresence>
        {confirmOptions && (
          <ConfirmationModal
            isOpen={true}
            onClose={() => handleConfirm(false)}
            onConfirm={() => handleConfirm(true)}
            {...confirmOptions}
          />
        )}
      </AnimatePresence>

      {/* Global Toast System */}
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ opacity: 0, y: -20, x: '-50%' }}
            animate={{ opacity: 1, y: 0, x: '-50%' }}
            exit={{ opacity: 0, y: -20, x: '-50%' }}
            className="fixed top-6 left-1/2 z-200 pointer-events-none"
          >
            <div className={`
              px-6 py-4 rounded-2xl shadow-2xl backdrop-blur-xl border border-white/10 flex items-center gap-3
              bg-zinc-900/95 text-white
            `}>
              <div className={`w-2 h-2 rounded-full animate-pulse ${
                toast.type === 'error' ? 'bg-red-500' : toast.type === 'success' ? 'bg-emerald-500' : 'bg-blue-500'
              }`} />
              <p className="text-[11px] font-black uppercase tracking-widest">{toast.message}</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </UIContext.Provider>
  );
}

export function useUI() {
  const context = useContext(UIContext);
  if (context === undefined) {
    throw new Error('useUI must be used within a UIProvider');
  }
  return context;
}
